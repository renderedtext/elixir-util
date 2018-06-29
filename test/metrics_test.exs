defmodule Util.MetricsTest do
  use ExUnit.Case

  alias Util.Metrics

  test "call with tag" do
    Metrics.benchmark("Foo", :bar, fn -> :ok end)
  end

  test "call without tag" do
    Metrics.benchmark("Foo", fn -> :ok end)
  end
end
