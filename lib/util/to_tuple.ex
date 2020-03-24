defmodule Util.ToTuple do
  @moduledoc false

  def ok(item), do: {:ok, item}

  def ok(item, atom) when is_atom(atom), do: {:ok, {atom, item}}
  def ok(item, _val), do: {:ok, item}

  def error(item), do: {:error, item}

  def error(item, atom) when is_atom(atom), do: {:error, {atom, item}}
  def error(item, _val), do: {:error, item}
end
