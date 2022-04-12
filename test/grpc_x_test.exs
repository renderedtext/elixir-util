defmodule Util.GrpcXTest do
  use ExUnit.Case
  import Mock

  alias Util.GrpcX

  setup_all do
    {:ok, server_pid} = start_helloworld_server()
    {:ok, clients_pid} = start_clients()

    on_exit(fn ->
      Process.exit(server_pid, :kill)
      Process.exit(clients_pid, :kill)
    end)
  end

  test "it can connect to existing services, result is in form {:ok, reply}" do
    req = Helloworld.HelloRequest.new(name: "shiroyasha")

    assert {:ok, reply} = GrpcX.call(:hello_service, :say_hello, req)
    assert reply.message == "Hello shiroyasha"
  end

  test "it raises an error if you pass an unknown service name" do
    req = Helloworld.HelloRequest.new(name: "shiroyasha")

    assert {:error, err} = GrpcX.call(:hellooooooo, :say_hello, req)
    assert err == "GrpcX client with name='hellooooooo' not registered in GrpcX"
  end

  test "it raises an error if you request an unknown rpc method" do
    req = Helloworld.HelloRequest.new(name: "shiroyasha")

    assert {:error, {:unknown_rpc, err}} = GrpcX.call(:hello_service, :describe, req)

    assert err == "no RPC method named='describe'"
  end

  test "it timeouts long calls" do
    req = Helloworld.HelloRequest.new(name: "please take a long time")

    assert {:error, err} = GrpcX.call(:hello_service, :say_hello, req, timeout: 500)
    assert err == %GRPC.RPCError{message: "Deadline expired", status: 4}
  end

  test "it reports connection errors" do
    req = Helloworld.HelloRequest.new(name: "please take a long time")

    assert {:error, err} = GrpcX.call(:not_running_service, :say_hello, req)
    assert err == "Error when opening connection: :timeout"
  end

  describe "when metrics are disabled" do
    test_with_mock "no increments are submitted", Watchman, [:passthrough], [] do
      req = Helloworld.HelloRequest.new(name: "shiroyasha")
      GrpcX.call(:hello_service_not_measured, :say_hello, req)

      assert_not_called(Watchman.increment(:_))
    end

    test_with_mock "no benchmarks are submitted", Watchman, [:passthrough], [] do
      req = Helloworld.HelloRequest.new(name: "shiroyasha")
      GrpcX.call(:hello_service_not_measured, :say_hello, req)

      assert_not_called(Watchman.benchmark(:_, :_))
    end
  end

  describe "when metrics are enabled" do
    test_with_mock "it measures number of connections", Watchman, [:passthrough], [] do
      req = Helloworld.HelloRequest.new(name: "shiroyasha")
      GrpcX.call(:hello_service, :say_hello, req)

      assert_called(Watchman.increment("grpc.hello_service.say_hello.connect.count"))
    end

    test_with_mock "it measures number of requests", Watchman, [:passthrough], [] do
      req = Helloworld.HelloRequest.new(name: "shiroyasha")
      GrpcX.call(:hello_service, :say_hello, req)

      assert_called(Watchman.increment("grpc.hello_service.say_hello.request.count"))
    end

    test_with_mock "it measures connection failures", Watchman, [:passthrough], [] do
      req = Helloworld.HelloRequest.new(name: "shiroyasha")
      GrpcX.call(:not_running_service, :say_hello, req)

      assert_called(Watchman.increment("grpc.not_running_service.say_hello.connect.error.count"))
    end

    test_with_mock "it measures response successes", Watchman, [:passthrough], [] do
      req = Helloworld.HelloRequest.new(name: "shiroyasha")
      GrpcX.call(:hello_service, :say_hello, req)

      assert_called(Watchman.increment("grpc.hello_service.say_hello.response.success.count"))
    end

    test_with_mock "it measures response errors", Watchman, [:passthrough], [] do
      req = Helloworld.HelloRequest.new(name: "please fail")
      GrpcX.call(:hello_service, :say_hello, req)

      assert_called(Watchman.increment("grpc.hello_service.say_hello.response.error.count"))
    end

    test_with_mock "it measures the duration of the rpc call", Watchman, [:passthrough], [] do
      req = Helloworld.HelloRequest.new(name: "shiroyasha")
      GrpcX.call(:hello_service, :say_hello, req)

      assert_called(Watchman.benchmark("grpc.hello_service.say_hello.duration", :_))
    end
  end

  def start_helloworld_server() do
    {:ok, pid, _} = GRPC.Server.start(Helloworld.Greeter.Server, 50_052)
    {:ok, pid}
  end

  def start_clients() do
    clients = [
      Util.GrpcX.Client.new(:hello_service, "localhost:50052", Helloworld.Greeter.Stub),
      Util.GrpcX.Client.new(:not_running_service, "localhost:60000", Helloworld.Greeter.Stub),
      Util.GrpcX.Client.new(
        :hello_service_not_measured,
        "localhost:50052",
        Helloworld.Greeter.Stub,
        publish_metrics: false
      )
    ]

    Util.GrpcX.start_link(clients)
  end
end
