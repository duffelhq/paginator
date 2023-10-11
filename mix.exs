defmodule Paginator.Mixfile do
  use Mix.Project

  @source_url "https://github.com/stordco/paginator"
  @version "1.2.0"

  def project do
    [
      app: :paginator,
      name: "Paginator",
      description: "Cursor based pagination for Elixir Ecto",
      version: @version,
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      source_url: @source_url,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test,
        "coveralls.circle": :test
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
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev], runtime: false},
      {:ecto, "~> 3.0"},
      {:ecto_sql, "~> 3.0"},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:ex_machina, "~> 2.1", only: :test},
      {:inch_ex, "~> 2.0", only: [:dev, :test]},
      {:postgrex, "~> 0.13", optional: true},
      {:plug_crypto, "~> 1.2.0"}
    ]
  end

  defp package do
    [
      description: "Cursor based pagination for Elixir Ecto.",
      maintainers: ["Steve Domin", "Stord, Inc."],
      licenses: ["MIT"],
      links: %{
        "Changelog" => "https://github.com/stordco/paginator/releases",
        "GitHub" => @source_url
      }
    ]
  end

  defp docs do
    [
      extras: [
        "CHANGELOG.md",
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      canonical: "http://hexdocs.pm/paginator",
      source_url: @source_url,
      source_ref: "v#{@version}"
    ]
  end
end
