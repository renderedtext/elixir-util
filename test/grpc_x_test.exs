defmodule Util.GrpcXTest do
  use ExUnit.Case

  alias Util.GrpcX

  setup_all do
    clients = [
      Util.GrpcX.Client.new(:service_a, "localhost:50051", :test, 1000),
      Util.GrpcX.Client.new(:service_b, "localhost:50051", :test, 1000)
    ]

    {:ok, pid} = Util.GrpcX.start_link(clients)

    on_exit(fn -> Process.exit(pid, :kill) end)
  end

  test "first test" do
    assert {:timeout, 1000} = GrpcX.call(:service_a, :describe, %{})
  end
end
