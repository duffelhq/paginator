defmodule Paginator do
  @moduledoc """
  Documentation for Paginator.
  """

  import Ecto.Query

  alias Paginator.{Config, Ecto.Query, Page, Page.Metadata}

  defmacro __using__(opts) do
    quote do
      @defaults unquote(opts)

      def paginate(queryable, opts \\ [], repo_opts \\ []) do
        opts = Keyword.merge(@defaults, opts)
        config = Config.new(opts)

        Paginator.paginate(queryable, config, __MODULE__, repo_opts)
      end
    end
  end

  def paginate(queryable, config, repo, repo_opts) do
    sorted_entries = entries(queryable, config, repo, repo_opts)
    paginated_entries = paginate_entries(sorted_entries, config)

    %Page{
      entries: paginated_entries,
      metadata: %Metadata{
        before: before_cursor(paginated_entries, sorted_entries, config),
        after: after_cursor(paginated_entries, sorted_entries, config),
        limit: config.limit,
        total_count: total_count(queryable, config, repo, repo_opts),
      }
    }
  end

  defp before_cursor([], [], _config), do: nil
  defp before_cursor(_paginated_entries, _sorted_entries, %Config{after: nil, before: nil}), do: nil
  defp before_cursor(paginated_entries, _sorted_entries, %Config{after: c_after} = config) when not is_nil(c_after) do
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
  defp after_cursor(paginated_entries, _sorted_entries, %Config{before: c_before} = config) when not is_nil(c_before) do
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

  defp fetch_cursor_value(schema, %Config{cursor_fetcher: nil, cursor_field: cursor_field}), do: Map.get(schema, cursor_field)
  defp fetch_cursor_value(schema, %Config{cursor_fetcher: cursor_fetcher}) do
    cursor_fetcher.(schema)
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

  defp total_count(_queryable, %Config{include_total_count: false}, _repo, _repo_opts), do: nil
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

    %{
      total_count: Enum.min([result, total_count_limit]),
      total_count_cap_exceeded: result > total_count_limit
    }
  end

  # `sorted_entries` returns (limit+1) records, so before
  # returning the page, we want to take only the first (limit).
  #
  # When we have only a before cursor, we get our results from
  # sorted_entries in reverse order due t
  defp paginate_entries(sorted_entries, %Config{before: before, after: nil, limit: limit}) when not is_nil(before) do
    sorted_entries
    |> Enum.take(limit)
    |> Enum.reverse()
  end
  defp paginate_entries(sorted_entries, %Config{limit: limit}) do
    Enum.take(sorted_entries, limit)
  end
end
