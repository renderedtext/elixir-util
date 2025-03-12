defmodule Util.Result do
  @doc """
  A result monad similar to one that exists in Rust/Haskell/...

  The main use case is to have an easily pipeble {:ok, val} | {:error, val}.

    result = endpoint
            |> Result.ok()
            |> Result.then(fn endpoint -> connect(endpoint) end)
            |> Result.then(fn channel -> send_req(channel, "hello") end)
            |> Result.then(fn result -> submit_metrics(result) end)

    case result do
      {:ok, val} -> val...
      {:error, err} -> err...
    end

  The above code would be identival to either a with statement:

    with {:ok, channel} <- connect(endpoint),
         {:ok, result} <- send_req(channel, "hello"),
         {:ok, result} <- submit_metrics(result) do
          val
    else
      {:error, error} -> error...
    end

  Or to a series of pipable functions that pattern match on :ok, :error:

    result = {:ok, endpoint}
             |> connect(endpoint) end)
             |> send_req(channel, "hello")
             |> submit_metrics(result)

    def connect({:ok, endpoint}), do: ...
    def connect({:error, err}), do: {:error, err}

    def send_req({:ok, channel}), do: ...
    def send_req({:error, err}), do: {:error, err}

    def submit_metrics({:ok, result}), do: ...
    def submit_metrics({:error, err}), do: {:error, err}

  So why would you choose Result over with or pattern matched functions:

    1. "with" is not working hand-in-hand with pipes, and usually it prevents
       you from splitting the pipeing logic into multiple functions

    2. Functions and pattern matching is just too many boilerplate.

  """

  @type then_function :: (ok_val() -> any)
  @type ok_val :: {:ok, any}
  @type error_val :: {:error, any}

  @type t() :: ok_val() | error_val()

  @spec ok(any()) :: ok_val()
  def ok(val), do: {:ok, val}

  @spec wrap(any()) :: ok_val()
  def wrap(val), do: ok(val)

  @spec error(any) :: error_val()
  def error(val), do: {:error, val}

  @spec then(any, then_function) :: any
  def then({:ok, val}, f), do: f.(val)
  def then(anything_else, _f), do: anything_else

  @spec unwrap(Result.t()) :: any()
  def unwrap({:ok, val}), do: val
  def unwrap(any), do: any

  @spec ok?(Result.t()) :: boolean()
  def ok?({:ok, _}), do: true
  def ok?(_), do: false

  @spec error?(Result.t()) :: boolean()
  def error?({:error, _}), do: false
  def error?(_), do: true
end
