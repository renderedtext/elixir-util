defmodule Util.Mixfile do
  use Mix.Project

  def project do
    [
      app: :util,
      version: "0.0.1",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  def elixirc_paths(:test), do: ["lib", "test/protos"]
  def elixirc_paths(:dev), do: ["lib", "test/protos"]
  def elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:watchman, github: "renderedtext/ex-watchman"},
      {:wormhole, "~> 2.2"},
      {:protobuf, "~> 0.5"},
      {:grpc, "0.5.0-beta.1", override: true},
      {:mock, "~> 0.3.0", only: :test}
    ]
  end
end
