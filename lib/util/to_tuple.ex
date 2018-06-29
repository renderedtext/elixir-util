defmodule Util.ToTuple do
  @moduledoc false

  def ok(item), do: {:ok, item}

  def error(item), do: {:error, item}
end
