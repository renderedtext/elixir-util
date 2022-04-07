defmodule Util.Grpc do
  @moduledoc """
  This module provides an opiniated interface for communicating with
  GRPC services. It handles starting and closing connections, logging,
  metrics, and proper error handling.

  Usage:

  1. First, add Util.Grpc to your application's supervision tree.
     This process keeps the configuration values for your Grpc clients.

     children = [
       worker(Util.Grpc, [])
     ]

     Supervisor.start_link(children, opts)

  2. Describe the outgoing connections from your service:

     Util.Grpc.setup([
       Util.Grpc.Client.new(:user_service, "localhost:50051", UserApi.Stub),
       Util.Grpc.Client.new(:billing_service, "localhost:50051", BillingApi.Stub)
     ])

  3. User Grpc.do to communicate with your upstream services:

    req = ExampleApi.DescribeRequest.new(name: "a")

    {:ok, res} = Util.Grpc.call(:user_service, :describe, req)

  During the execution of the call, the following metrics are published:

    - gprc.<client_name>.<method_name>.duration
    - gprc.<client_name>.<method_name>.connect
    - gprc.<client_name>.<method_name>.connect.error.count
    - gprc.<client_name>.<method_name>.response.success.count
    - gprc.<client_name>.<method_name>.response.error.count

  In case of errors, log messages are logged via the Logger module.
  """

  @type client_name :: String.t()

  def start_link do
    Util.Grpc.State.start_link()
  end

  @doc """
  Sets up Grpc connection information.

  Example:

    Util.Grpc.setup([
      Client.new(:service_a, Application.get_env("SERVICE_A_ENDPOINT"), :info, true)
      Client.new(:service_b, Application.get_env("SERVICE_B_ENDPOINT"), :info, true)
    ])

  """
  def setup(clients) do
    :ok = State.reset()

    Enum.each(clients, fn c -> Util.Grpc.State.add_client(c) end)

    :ok
  end

  @doc """
  Executes a stateless RPC call to a remote service.

  1. It opens a new connection
  2. Sends the RPC request
  3. Waits for the result, or times out
  """
  @spec rpc(client_name(), GRPC.Channel.t(), function()) ::
          {:ok, any()}
          | {:error, :failed_to_connect, any()}
          | {:error, :timeout, any()}
          | {:error, any()}
  def call(client_name, callback) do
    {:ok, client} = State.find_client(client_name)

    Client.rpc(client, callback)
  end
end
