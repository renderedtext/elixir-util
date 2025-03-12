defmodule Helloworld.Greeter.Server do
  use GRPC.Server, service: Helloworld.Greeter.Service

  alias Helloworld.{HelloReply, HelloRequest}

  @spec say_hello(HelloRequest.t(), GRPC.Server.Stream.t()) :: HelloReply.t()
  def say_hello(request, _stream) do
    case request.name do
      "please take a long time" ->
        :timer.sleep(60_000)
        Helloworld.HelloReply.new(message: "Hello")

      "please fail" ->
        raise "I'm failing"

      name ->
        Helloworld.HelloReply.new(message: "Hello #{name}")
    end
  end
end
