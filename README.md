# Paginator

[![Build Status](https://travis-ci.org/duffelhq/paginator.svg?branch=master)](https://travis-ci.org/duffelhq/paginator)
[![Inline docs](http://inch-ci.org/github/duffelhq/paginator.svg)](http://inch-ci.org/github/duffelhq/paginator)

[Cursor based pagination](http://use-the-index-luke.com/no-offset) for Elixir [Ecto](https://github.com/elixir-ecto/ecto).

[Documentation](https://hexdocs.pm/paginator)

## Getting started

```elixir
defmodule MyApp.Repo do
  use Ecto.Repo, otp_app: :my_app
  use Paginator
end

query = from(p in Post, order_by: [asc: p.inserted_at, asc: p.id])

page = MyApp.Repo.paginate(cursor_fields: [:inserted_at, :id], limit: 50)

# `page.entries` contains all the entries for this page.
# `page.metadata` contains the metadata associated with this page (cursors, limit, total count)
```

## Install

Add `paginator` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:paginator, "~> 0.1"}]
end
```

## Usage

1. Add `Paginator` to your repo.

    ```elixir
    defmodule MyApp.Repo do
      use Ecto.Repo, otp_app: :my_app
      use Paginator
    end
    ```

2. Use the `paginate` function to paginate your queries.

    ```elixir
    query = from(p in Post, order_by: [asc: p.inserted_at, asc: p.id])

    # return the first 50 posts
    %{entries: entries, metadata: metadata} = Repo.paginate(cursor_fields: [:inserted_at, :id], limit: 50)

    # assign the `after` cursor to a variable
    cursor_after = metadata.after

    # return the next 50 posts
    %{entries: entries, metadata: metadata} = Repo.paginate(after: cursor_after, cursor_fields: [:inserted_at, :id], limit: 50)

    # assign the `after` cursor to a variable
    cursor_before = metadata.before

    # return the previous 50 posts (if no post was created in between it should be the same list as in our first call to `paginate`)
    %{entries: entries, metadata: metadata} = Repo.paginate(before: cursor_before, cursor_fields: [:inserted_at, :id], limit: 50)

    # return total count
    # NOTE: this will issue a separate `SELECT COUNT(*) FROM table` query to the database.
    %{entries: entries, metadata: metadata} = Repo.paginate(include_total_count: true, cursor_fields: [:inserted_at, :id], limit: 50)

    IO.puts "total count: #{metadata.total_count}"
    ```

## Caveats

* This library has only be tested with PostgreSQL.
* You need to add order_by clauses yourself before passing your query to `paginate/2`. In the future we might do that
for you automatically based on the fields specified in `:cursor_fields`.
* It is not possible to use the column from a joined resource as a cursor. This limitation will be lifted once support for
[named joints](https://github.com/elixir-ecto/ecto/issues/2389) lands in Ecto 3.0.
* There is an outstanding issue where Postgrex fails to properly builds the query if it includes custom PostgreSQL types.

## Documentation

Documentation is written into the library, you will find it in the source code, accessible from `iex` and of course, it
all gets published to [hexdocs](http://hexdocs.pm/paginator).

## Contributing

### Running tests

Clone the repo and fetch its dependencies:

```
$ git clone https://github.com/duffelhq/paginator.git
$ cd paginator
$ mix deps.get
$ mix test
```

### Building docs

```
$ mix docs
```

## LICENSE

See [LICENSE](https://github.com/duffelhq/paginator/blob/master/LICENSE.txt)
