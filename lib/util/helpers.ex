defmodule Util.Helpers do
  @moduledoc """
  Miscellaneous helpers
  """

  def non_empty_value_or_default(map, key, default) do
    case Map.get(map, key) do
      val when is_integer(val) and val > 0 -> {:ok, val}
      val when is_binary(val) and val != "" -> {:ok, val}
      val when is_list(val) and length(val) > 0 -> {:ok, val}
      _ -> {:ok, default}
    end
  end

  def not_empty_string(map, key, error_atom \\ "") do
    case Map.get(map, key) do
      value when is_binary(value) and value != "" ->
        {:ok, value}
      error_val ->
        "'#{key}' - invalid value: '#{error_val}', it must be a not empty string."
        |> Util.ToTuple.error(error_atom)
    end
  end
end
