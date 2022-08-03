defmodule Util.Mixfile do
  use Mix.Project

  def project do
    [app: :util,
     version: "0.0.1",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:watchman, github: "renderedtext/ex-watchman"},
      {:wormhole, "~> 2.2"},
      {:protobuf, "~> 0.5"},
      {:mock, "~> 0.3.0", only: :test},
      {:uuid, "~> 1.1"}
    ]
  end
end
