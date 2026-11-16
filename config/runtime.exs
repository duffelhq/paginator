import Config

if config_env() == :test do
  config :paginator, Paginator.Repo,
    pool: Ecto.Adapters.SQL.Sandbox,
    username: System.get_env("PAGINATOR_REPO_USERNAME", "postgres"),
    password: System.get_env("PAGINATOR_REPO_PASSWORD", "postgres"),
    database: System.get_env("PAGINATOR_REPO_DATABASE", "paginator_test")
end
