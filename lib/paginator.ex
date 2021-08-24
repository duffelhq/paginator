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

  ## Options

  `Paginator` can take any options accepted by `paginate/3`. This is useful when
  you want to enforce some options globally across your project.

  ### Example

      defmodule MyApp.Repo do
        use Ecto.Repo, otp_app: :my_app
        use Paginator,
          limit: 10,                           # sets the default limit to 10
          maximum_limit: 100,                  # sets the maximum limit to 100
          include_total_count: true,           # include total count by default
          total_count_primary_key_field: :uuid # sets the total_count_primary_key_field to uuid for calculate total_count
      end

  Note that these values can be still be overridden when `paginate/3` is called.

  ### Use without macros

  If you wish to avoid use of macros or you wish to use a different name for
  the pagination function you can define your own function like so:

      defmodule MyApp.Repo do
        use Ecto.Repo, otp_app: :my_app

        def my_paginate_function(queryable, opts \\ [], repo_opts \\ []) do
          defaults = [limit: 10] # Default options of your choice here
          opts = Keyword.merge(defaults, opts)
          Paginator.paginate(queryable, opts, __MODULE__, repo_opts)
        end
      end
  """

  import Ecto.Query

  alias Paginator.{Config, Cursor, Ecto.Query, Page, Page.Metadata}

  defmacro __using__(opts) do
    quote do
      @defaults unquote(opts)

      def paginate(queryable, opts \\ [], repo_opts \\ []) do
        opts = Keyword.merge(@defaults, opts)

        Paginator.paginate(queryable, opts, __MODULE__, repo_opts)
      end
    end
  end

  @doc """
  Fetches all the results matching the query within the cursors.

  ## Options

    * `:after` - Fetch the records after this cursor.
    * `:before` - Fetch the records before this cursor.
    * `:cursor_fields` - The fields with sorting direction used to determine the
    cursor. In most cases, this should be the same fields as the ones used for sorting in the query.
    When you use named bindings in your query they can also be provided.
    * `:fetch_cursor_value_fun` function of arity 2 to lookup cursor values on returned records.
    Defaults to `Paginator.default_fetch_cursor_value/2`
    * `:include_total_count` - Set this to true to return the total number of
    records matching the query. Note that this number will be capped by
    `:total_count_limit`. Defaults to `false`.
    * `:total_count_primary_key_field` - Running count queries on specified column of the table
    * `:limit` - Limits the number of records returned per page. Note that this
    number will be capped by `:maximum_limit`. Defaults to `50`.
    * `:maximum_limit` - Sets a maximum cap for `:limit`. This option can be useful when `:limit`
    is set dynamically (e.g from a URL param set by a user) but you still want to
    enfore a maximum. Defaults to `500`.
    * `:sort_direction` - The direction used for sorting. Defaults to `:asc`.
    It is preferred to set the sorting direction per field in `:cursor_fields`.
    * `:total_count_limit` - Running count queries on tables with a large number
    of records is expensive so it is capped by default. Can be set to `:infinity`
    in order to count all the records. Defaults to `10,000`.
    * `:page_booleans` - populates `:has_next_page` and `:has_previous_page` booleans.
    Always returns an `:after` and `:before` cursor (if available). This mimics
    [relay style pagination](https://relay.dev/graphql/connections.htm#sec-undefined.PageInfo)

  ## Repo options

  This will be passed directly to `Ecto.Repo.all/2`, as such any option supported
  by this function can be used here.

  ## Simple example

      query = from(p in Post, order_by: [asc: p.inserted_at, asc: p.id], select: p)

      Repo.paginate(query, cursor_fields: [:inserted_at, :id], limit: 50)

  ## Example with using custom sort directions per field

      query = from(p in Post, order_by: [asc: p.inserted_at, desc: p.id], select: p)

      Repo.paginate(query, cursor_fields: [inserted_at: :asc, id: :desc], limit: 50)

  ## Example with sorting on columns in joined tables

      from(
        p in Post,
        as: :posts,
        join: a in assoc(p, :author),
        as: :author,
        preload: [author: a],
        select: p,
        order_by: [
          {:asc, a.name},
          {:asc, p.id}
        ]
      )

      Repo.paginate(query, cursor_fields: [{{:author, :name}, :asc}, id: :asc], limit: 50)

  When sorting on columns in joined tables it is necessary to use named bindings. In
  this case we name it `author`. In the `cursor_fields` we refer to this named binding
  and its column name.

  To build the cursor Paginator uses the returned Ecto.Schema. When using a joined
  column the returned Ecto.Schema won't have the value of the joined column
  unless we preload it. E.g. in this case the cursor will be build up from
  `post.id` and `post.author.name`. This presupposes that the named of the
  binding is the same as the name of the relationship on the original struct.

  One level deep joins are supported out of the box but if we join on a second
  level, e.g. `post.author.company.name` a custom function can be supplied to
  handle the cursor value retrieval. This also applies when the named binding
  does not map to the name of the relationship.

  ## Example
      from(
        p in Post,
        as: :posts,
        join: a in assoc(p, :author),
        as: :author,
        join: c in assoc(a, :company),
        as: :company,
        preload: [author: a],
        select: p,
        order_by: [
          {:asc, a.name},
          {:asc, p.id}
        ]
      )

      Repo.paginate(query,
        cursor_fields: [{{:company, :name}, :asc}, id: :asc],
        fetch_cursor_value_fun: fn
          post, {:company, name} ->
            post.author.company.name

          post, field ->
            Paginator.default_fetch_cursor_value(post, field)
        end,
        limit: 50
      )

  """
  @callback paginate(queryable :: Ecto.Query.t(), opts :: Keyword.t(), repo_opts :: Keyword.t()) ::
              Paginator.Page.t()

  @doc false
  def paginate(queryable, opts, repo, repo_opts) do
    config = Config.new(opts)

    Config.validate!(config)

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
        total_count_cap_exceeded: total_count_cap_exceeded,
        has_next_page: has_next_page(paginated_entries, sorted_entries, config),
        has_previous_page: has_previous_page(paginated_entries, sorted_entries, config),
      }
    }
  end

  @doc """
  Generate a cursor for the supplied record, in the same manner as the
  `before` and `after` cursors generated by `paginate/3`.

  For the cursor to be compatible with `paginate/3`, `cursor_fields`
  must have the same value as the `cursor_fields` option passed to it.

  ### Example

      iex> Paginator.cursor_for_record(%Paginator.Customer{id: 1}, [:id])
      "g3QAAAABZAACaWRhAQ=="

      iex> Paginator.cursor_for_record(%Paginator.Customer{id: 1, name: "Alice"}, [id: :asc, name: :desc])
      "g3QAAAACZAACaWRhAWQABG5hbWVtAAAABUFsaWNl"
  """
  @spec cursor_for_record(any(), [atom() | {atom(), atom()}], (map(), atom() | {atom(), atom()} -> any())) :: binary()
  def cursor_for_record(
        record,
        cursor_fields,
        fetch_cursor_value_fun \\ &Paginator.default_fetch_cursor_value/2
      ) do
    fetch_cursor_value(record, %Config{
      cursor_fields: cursor_fields,
      fetch_cursor_value_fun: fetch_cursor_value_fun
    })
  end

  @doc """
  Default function used to get the value of a cursor field from the supplied
  map. This function can be overridden in the `Paginator.Config` using the
  `fetch_cursor_value_fun` key.

  When using named bindings to sort on joined columns it will attempt to get
  the value of joined column by using the named binding as the name of the
  relationship on the original Ecto.Schema.

  ### Example

      iex> Paginator.default_fetch_cursor_value(%Paginator.Customer{id: 1}, :id)
      1

      iex> Paginator.default_fetch_cursor_value(%Paginator.Customer{id: 1, address: %Paginator.Address{city: "London"}}, {:address, :city})
      "London"
  """

  @spec default_fetch_cursor_value(map(), atom() | {atom(), atom()}) :: any()
  def default_fetch_cursor_value(schema, {binding, field})
      when is_atom(binding) and is_atom(field) do
    case Map.get(schema, field) do
      nil -> Map.get(schema, binding) |> Map.get(field)
      value -> value
    end
  end

  def default_fetch_cursor_value(schema, field) when is_atom(field) do
    Map.get(schema, field)
  end

  defp before_cursor([], [], _config), do: nil

  defp before_cursor(_paginated_entries, _sorted_entries, %Config{after: nil, before: nil}),
    do: nil

  defp before_cursor(paginated_entries, _sorted_entries, %Config{after: c_after} = config)
       when not is_nil(c_after) do
    first_or_nil(paginated_entries, config)
  end

  defp before_cursor(paginated_entries, _sorted_entries, %Config{page_booleans: true} = config) do
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

  defp after_cursor(paginated_entries, _sorted_entries, %Config{page_booleans: true} = config) do
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

  defp has_next_page(_paginated_entries, _sorted_entries, %Config{page_booleans: false}) do
    nil
  end

  defp has_next_page([], [], _config) do
    false
  end

  defp has_next_page(_paginated_entries, _sorted_entries, %Config{before: c_before})
      when not is_nil(c_before) do
    true
  end

  defp has_next_page(_paginated_entries, sorted_entries, config) do
    !last_page?(sorted_entries, config)
  end

  defp has_previous_page(_paginated_entries, _sorted_entries, %Config{page_booleans: false}) do
    nil
  end

  defp has_previous_page([], [], _config) do
    false
  end

  defp has_previous_page(_paginated_entries, _sorted_entries, %Config{after: nil, before: nil}) do
    false
  end

  defp has_previous_page(_paginated_entries, _sorted_entries, %Config{after: c_after})
       when not is_nil(c_after) do
    true
  end

  defp has_previous_page(_paginated_entries, sorted_entries, config) do
    !first_page?(sorted_entries, config)
  end

  defp fetch_cursor_value(schema, %Config{
         cursor_fields: cursor_fields,
         fetch_cursor_value_fun: fetch_cursor_value_fun
       }) do
    cursor_fields
    |> Enum.map(fn
      {cursor_field, _order} ->
        {cursor_field, fetch_cursor_value_fun.(schema, cursor_field)}

      cursor_field when is_atom(cursor_field) ->
        {cursor_field, fetch_cursor_value_fun.(schema, cursor_field)}
    end)
    |> Map.new()
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

  defp total_count(
         queryable,
         %Config{
           total_count_limit: :infinity,
           total_count_primary_key_field: total_count_primary_key_field
         },
         repo,
         repo_opts
       ) do
    result =
      queryable
      |> exclude(:preload)
      |> exclude(:select)
      |> exclude(:order_by)
      |> select([e], struct(e, [total_count_primary_key_field]))
      |> subquery
      |> select(count("*"))
      |> repo.one(repo_opts)

    {result, false}
  end

  defp total_count(
         queryable,
         %Config{
           total_count_limit: total_count_limit,
           total_count_primary_key_field: total_count_primary_key_field
         },
         repo,
         repo_opts
       ) do
    result =
      queryable
      |> exclude(:preload)
      |> exclude(:select)
      |> exclude(:order_by)
      |> limit(^(total_count_limit + 1))
      |> select([e], struct(e, [total_count_primary_key_field]))
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
