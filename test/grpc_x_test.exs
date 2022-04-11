defmodule Util.GrpcXTest do
  use ExUnit.Case

  alias Util.GrpcX

  setup_all do
    server_pid = start_helloworld_server()
    clients_pid = start_clients()

    on_exit(fn ->
      Process.exit(server_pid, :kill)
      Process.exit(clients_pid, :kill)
    end)
  end

  test "connecting to an existing services works and returns an {:ok, reply} tuple" do
    req = Helloworld.HelloRequest.new(name: "shiroyasha")

    assert {:ok, reply} = GrpcX.call(:hello_service, :say_hello, req)
    assert reply.message == "Hello shiroyasha"
  end

  def start_helloworld_server() do
    spawn_link(fn ->
      GRPC.Server.start(Helloworld.Greeter.Server, 50_051)
    end)
  end

  def start_clients() do
    clients = [
      Util.GrpcX.Client.new(:hello_service, "localhost:50051", Helloworld.Greeter.Stub)
    ]

    {:ok, client_pid} = Util.GrpcX.start_link(clients)
  end
end
