use Mix.Config

config :paginator, ecto_repos: [Paginator.Repo]

config :paginator, Paginator.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox,
  username: "postgres",
  password: "postgres",
  database: "paginator_test"

config :logger, :console,
  level: :warn
