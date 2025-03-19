defmodule Paginator.Mixfile do
  use Mix.Project

  @source_url "https://github.com/duffelhq/paginator"
  @version "1.2.0"

  def project do
    [
      app: :paginator,
      name: "Paginator",
      version: @version,
      elixir: "~> 1.5",
      elixirc_options: [warnings_as_errors: System.get_env("CI") == "true"],
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ],
      package: package(),
      docs: docs()
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
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ecto, "~> 3.0"},
      {:ecto_sql, "~> 3.0"},
      {:ex_doc, "~> 0.18", only: :dev, runtime: false},
      {:ex_machina, "~> 2.1", only: :test},
      {:inch_ex, "~> 2.0", only: [:dev, :test]},
      {:postgrex, "~> 0.13", optional: true},
      {:plug_crypto, "~> 2.1.0"}
    ]
  end

  defp package do
    [
      description: "Cursor based pagination for Elixir Ecto.",
      maintainers: ["Steve Domin"],
      licenses: ["MIT"],
      links: %{
        "Changelog" => "https://hexdocs.pm/paginator/changelog.html",
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
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end
end
