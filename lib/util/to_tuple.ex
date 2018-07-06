defmodule Util.ToTuple do
  @moduledoc false

  def ok(item), do: {:ok, item}

  def error(item), do: {:error, item}
  
  def error(item, atom) when is_atom(atom), do: {:error, {atom, item}}
end
