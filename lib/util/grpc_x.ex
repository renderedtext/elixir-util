defmodule Util.GrpcX do
  @moduledoc """
  This module provides an opiniated interface for communicating with
  GRPC services. It handles starting and closing connections, logging,
  metrics, and proper error handling.

  Usage:

  1. First, add Util.Grpc to your application's supervision tree.
     This process keeps the configuration values for your Grpc clients.

     grpc_clients = [
       Util.Grpc.Client.new(:user_service, "localhost:50051", UserApi.Stub),
       Util.Grpc.Client.new(:billing_service, "localhost:50051", BillingApi.Stub)
     ]

     children = [
       worker(Util.Grpc, gprc_clients)
     ]

     Supervisor.start_link(children, opts)

  3. Use Grpc.call to communicate with your upstream services:

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

  alias Util.GrpcX.State
  alias Util.GrpcX.Client

  @type client_name :: String.t()

  @spec start_link([Util.Grpc.Client.t()]) :: {:ok, pid()} | {:error, any()}
  def start_link(clients) do
    Util.GrpcX.State.start_link(clients)
  end

  @doc """
  Executes a stateless RPC call to a remote service.

  1. It opens a new connection
  2. Sends the RPC request
  3. Waits for the result, or times out
  """
  @spec call(client_name(), Atom.t(), any(), any()) :: Util.GrpcX.RPCCall.response()
  def call(client_name, method_name, request, opts \\ []) do
    {:ok, client} = State.find_client(client_name)

    Client.call(client, method_name, request, opts)
  end
end
