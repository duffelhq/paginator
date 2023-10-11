import Config

config :paginator, ecto_repos: [Paginator.Repo]

config :paginator, Paginator.Repo,
  port: 5432,
  username: "postgres",
  password: "postgres",
  database: "paginator_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :logger, :console, level: :warning
