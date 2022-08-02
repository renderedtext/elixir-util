defmodule Util.Proto.Transformations do
  @moduledoc """
  This module is intended as a simple way for initializing deeply nested Protobuf
  structures defined by protobuf-elixir modules.
  """

  @doc """
  ## Examples:

      iex> alias Util.Proto.Transformations
      iex> Transformations.string_to_enum_atom_or_0("name", "")
      0

      iex> alias Util.Proto.Transformations
      iex> Transformations.string_to_enum_atom_or_0("name", 1)
      0

      iex> alias Util.Proto.Transformations
      iex> Transformations.string_to_enum_atom_or_0("name", "value")
      :Value
  """
  def string_to_enum_atom_or_0(_field_name, field_value)
  when is_binary(field_value) and field_value != "" do
    field_value |> String.upcase() |> String.to_atom()
  end
  def string_to_enum_atom_or_0(_field_name, _field_value), do: 0


  @doc """
  ## Examples:

      iex> alias Util.Proto.Transformations
      iex> Transformations.date_time_to_timestamps("name", nil)
      %{seconds: 0, nanos: 0}

      iex> alias Util.Proto.Transformations
      iex> {:ok, time} = DateTime.new(~D[2016-05-24], ~T[13:26:08.003], "Etc/UTC")
      iex> Transformations.date_time_to_timestamps("name", time)
      %{seconds: 1464096368, nanos: 3000000}

      iex> alias Util.Proto.Transformations
      iex> Transformations.date_time_to_timestamps("name", %{seconds: 10, nanos: 10})
      %{seconds: 10, nanos: 10}

  """
  def date_time_to_timestamps(_field_name, nil), do: %{seconds: 0, nanos: 0}
  def date_time_to_timestamps(_field_name, date_time = %DateTime{}) do
    %{}
    |> Map.put(:seconds, DateTime.to_unix(date_time, :second))
    |> Map.put(:nanos, elem(date_time.microsecond, 0) * 1_000)
  end
  def date_time_to_timestamps(_field_name, value), do: value

  def atom_to_lower_string(_field_name, value),
  do: value |> Atom.to_string() |> String.downcase()
end
