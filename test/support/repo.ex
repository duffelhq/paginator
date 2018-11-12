defmodule Paginator.Repo do
  use Ecto.Repo,
    otp_app: :paginator,
    adapter: Ecto.Adapters.Postgres

  use Paginator
end
