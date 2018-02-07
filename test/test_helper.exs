Application.ensure_all_started(:postgrex)
Application.ensure_all_started(:ecto)

# Load up the repository, start it, and run migrations
_ = Ecto.Adapters.Postgres.storage_down(Paginator.Repo.config())
:ok = Ecto.Adapters.Postgres.storage_up(Paginator.Repo.config())
{:ok, _} = Paginator.Repo.start_link()
:ok = Ecto.Migrator.up(Paginator.Repo, 0, Paginator.TestMigration, log: false)

Ecto.Adapters.SQL.Sandbox.mode(Paginator.Repo, :manual)

ExUnit.start()
