defmodule Paginator.Mixfile do
  use Mix.Project

  def project do
    [app: :paginator,
     version: "0.1.0",
     elixir: "~> 1.4",
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [{:ecto, "~> 2.2"},
     {:postgrex, "~> 0.13", optional: true},
     {:ex_machina, "~> 2.0", only: :test}]
  end
end
