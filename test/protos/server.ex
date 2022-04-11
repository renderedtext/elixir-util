defmodule Helloworld.Greeter.Server do
  use GRPC.Server, service: Helloworld.Greeter.Service

  alias Helloworld.{HelloReply, HelloRequest}

  @spec say_hello(HelloRequest.t(), GRPC.Server.Stream.t()) :: HelloReply.t()
  def say_hello(request, _stream) do
    IO.inspect("Say Hello requested")

    Helloworld.HelloReply.new(message: "Hello #{request.name}")
  end
end
