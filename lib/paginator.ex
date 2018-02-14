defmodule Paginator do
  @moduledoc """
  Defines a paginator.

  This module adds a `paginate/3` function to your `Ecto.Repo` so that you can
  paginate through results using opaque cursors.

  ## Usage

      defmodule MyApp.Repo do
        use Ecto.Repo, otp_app: :my_app
        use Paginator
      end

  """

  import Ecto.Query

  alias Paginator.{Config, Cursor, Ecto.Query, Page, Page.Metadata}

  defmacro __using__(opts) do
    quote do
      @defaults unquote(opts)

      def paginate(queryable, opts \\ [], repo_opts \\ []) do
        opts = Keyword.merge(@defaults, opts)
        config = Config.new(opts)

        unless config.cursor_fields,
          do: raise("expected `:cursor_fields` to be set in call to paginate/3")

        Paginator.paginate(queryable, config, __MODULE__, repo_opts)
      end
    end
  end

  @doc """
  Fetches all the results matching the query within the cursors.

  ## Options

    * `:after` - Fetch the records after this cursor.
    * `:before` - Fetch the records before this cursor.
    * `:cursor_fields` - The fields used to determine the cursor. In most cases,
    this should be the same fields as the ones used for sorting in the query.
    * `:include_total_count` - Set this to true to return the total number of
    records matching the query. Note that this number will be capped by
    `:total_count_limit`. Defaults to `false`.
    * `:limit` - Limits the number of records returned per page. Note that this
    number will be capped by `:maximum_limit`. Defaults to `50`.
    * `:maximum_limit` - Sets a maximum cap for `:limit`. This option can be useful when `:limit`
    is set dynamically (e.g from a URL param set by a user) but you still want to
    enfore a maximum. Defaults to `500`.
    * `:sort_direction` - The direction used for sorting. Defaults to `:asc`.
    * `:total_count_limit` - Running count queries on tables with a large number
    of records is expensive so it is capped by default. Can be set to `:infinity`
    in order to count all the records. Defaults to `10,000`.

  ## Repo options

  This will be passed directly to `Ecto.Repo.all/2`, as such any option supported
  by this function can be used here.

  ## Example

      query = from(p in Post, order_by: [asc: p.inserted_at, asc: p.id], select: p)

      Repo.paginate(query, cursor_fields: [:inserted_at, :id], limit: 50)
  """
  @callback paginate(queryable :: Ecto.Query.t(), opts :: Keyword.t(), repo_opts :: Keyword.t()) ::
              Paginator.Page.t()

  @doc false
  def paginate(queryable, config, repo, repo_opts) do
    sorted_entries = entries(queryable, config, repo, repo_opts)
    paginated_entries = paginate_entries(sorted_entries, config)
    {total_count, total_count_cap_exceeded} = total_count(queryable, config, repo, repo_opts)

    %Page{
      entries: paginated_entries,
      metadata: %Metadata{
        before: before_cursor(paginated_entries, sorted_entries, config),
        after: after_cursor(paginated_entries, sorted_entries, config),
        limit: config.limit,
        total_count: total_count,
        total_count_cap_exceeded: total_count_cap_exceeded
      }
    }
  end

  defp before_cursor([], [], _config), do: nil

  defp before_cursor(_paginated_entries, _sorted_entries, %Config{after: nil, before: nil}),
    do: nil

  defp before_cursor(paginated_entries, _sorted_entries, %Config{after: c_after} = config)
       when not is_nil(c_after) do
    first_or_nil(paginated_entries, config)
  end

  defp before_cursor(paginated_entries, sorted_entries, config) do
    if first_page?(sorted_entries, config) do
      nil
    else
      first_or_nil(paginated_entries, config)
    end
  end

  defp first_or_nil(entries, config) do
    if first = List.first(entries) do
      fetch_cursor_value(first, config)
    else
      nil
    end
  end

  defp after_cursor([], [], _config), do: nil

  defp after_cursor(paginated_entries, _sorted_entries, %Config{before: c_before} = config)
       when not is_nil(c_before) do
    last_or_nil(paginated_entries, config)
  end

  defp after_cursor(paginated_entries, sorted_entries, config) do
    if last_page?(sorted_entries, config) do
      nil
    else
      last_or_nil(paginated_entries, config)
    end
  end

  defp last_or_nil(entries, config) do
    if last = List.last(entries) do
      fetch_cursor_value(last, config)
    else
      nil
    end
  end

  defp fetch_cursor_value(schema, %Config{cursor_fields: cursor_fields}) do
    cursor_fields
    |> Enum.map(fn field -> Map.get(schema, field) end)
    |> Cursor.encode()
  end

  defp first_page?(sorted_entries, %Config{limit: limit}) do
    Enum.count(sorted_entries) <= limit
  end

  defp last_page?(sorted_entries, %Config{limit: limit}) do
    Enum.count(sorted_entries) <= limit
  end

  defp entries(queryable, config, repo, repo_opts) do
    queryable
    |> Query.paginate(config)
    |> repo.all(repo_opts)
  end

  defp total_count(_queryable, %Config{include_total_count: false}, _repo, _repo_opts),
    do: {nil, nil}

  defp total_count(queryable, %Config{total_count_limit: :infinity}, repo, repo_opts) do
    result =
      queryable
      |> exclude(:preload)
      |> exclude(:select)
      |> exclude(:order_by)
      |> select([e], e.id)
      |> subquery
      |> select(count("*"))
      |> repo.one(repo_opts)

    {result, false}
  end

  defp total_count(queryable, %Config{total_count_limit: total_count_limit}, repo, repo_opts) do
    result =
      queryable
      |> exclude(:preload)
      |> exclude(:select)
      |> exclude(:order_by)
      |> limit(^(total_count_limit + 1))
      |> select([e], e.id)
      |> subquery
      |> select(count("*"))
      |> repo.one(repo_opts)

    {
      Enum.min([result, total_count_limit]),
      result > total_count_limit
    }
  end

  # `sorted_entries` returns (limit+1) records, so before
  # returning the page, we want to take only the first (limit).
  #
  # When we have only a before cursor, we get our results from
  # sorted_entries in reverse order due t
  defp paginate_entries(sorted_entries, %Config{before: before, after: nil, limit: limit})
       when not is_nil(before) do
    sorted_entries
    |> Enum.take(limit)
    |> Enum.reverse()
  end

  defp paginate_entries(sorted_entries, %Config{limit: limit}) do
    Enum.take(sorted_entries, limit)
  end
end
