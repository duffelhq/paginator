defmodule Paginator.Mixfile do
  use Mix.Project

  @version "1.0.4"

  def project do
    [
      app: :paginator,
      version: @version,
      elixir: "~> 1.5",
      elixirc_options: [warnings_as_errors: System.get_env("CI") == "true"],
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      deps: deps(),

      # Hex
      description: description(),
      package: package(),

      # Docs
      name: "Paginator",
      source_url: "https://github.com/duffelhq/paginator",
      homepage_url: "https://github.com/duffelhq/paginator",
      docs: [
        source_ref: "v#{@version}",
        main: "Paginator",
        canonical: "http://hexdocs.pm/paginator",
        source_url: "https://github.com/duffelhq/paginator"
      ]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:calendar, "~> 1.0.0", only: :test},
      {:ecto, "~> 3.0"},
      {:ecto_sql, "~> 3.0"},
      {:ex_doc, "~> 0.18", only: :dev, runtime: false},
      {:ex_machina, "~> 2.1", only: :test},
      {:inch_ex, "~> 2.0", only: [:dev, :test]},
      {:postgrex, "~> 0.13", optional: true},
      {:plug_crypto, "~> 1.2.0"}
    ]
  end

  defp description do
    """
    Cursor based pagination for Elixir Ecto.
    """
  end

  defp package do
    [
      maintainers: ["Steve Domin"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/duffelhq/paginator"}
    ]
  end
end
