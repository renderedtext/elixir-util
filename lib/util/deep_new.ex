defmodule Util.Proto do
  @moduledoc """

  """

  def deep_new(struct, args), do: deep_new(args, struct, "")

  defp deep_new(args, struct, _name) when is_list(args) or is_map(args) do
    args
    |> Enum.map(&init_property(struct, &1))
    |> apply_reverse(:new, struct)
  end

  defp deep_new(arg, _struct = :bool, _name) when is_boolean(arg), do: arg
  defp deep_new(arg, _struct = :bool, name),
    do: raise "Field: '#{name}': Expected boolean argument, got '#{inspect arg}'"

  defp deep_new(arg, _struct = :string, _name) when is_binary(arg), do: arg
  defp deep_new(arg, _struct = :string, name),
    do: raise "Field: '#{name}': Expected string argument, got '#{inspect arg}'"

  defp deep_new(arg, _struct = :enum, _name) when is_integer(arg), do: arg
  defp deep_new(arg, _struct = :enum, name),
    do: raise "Field: '#{name}': Expected integer or atom argument, got '#{inspect arg}'"

  defp deep_new(arg, struct, _name)
    when struct in [:int32, :int64, :uint32, :uint64, :sint32, :sint64] and
      is_integer(arg), do: arg
  defp deep_new(arg, struct, name)
    when struct in [:int32, :int64, :uint32, :uint64, :sint32, :sint64],
    do: raise "Field: '#{name}': Expected #{inspect struct} argument, got '#{inspect arg}'"

  defp deep_new(arg, struct, _name)
    when struct in [:fixed32, :fixed64, :sfixed32, :sfixed64, :float, :double] and
      is_float(arg), do: arg
  defp deep_new(arg, struct, name)
    when struct in [:fixed32, :fixed64, :sfixed32, :sfixed64, :float, :double],
    do: raise "Field: '#{name}': Expected #{inspect struct} argument, got '#{inspect arg}'"

  defp init_property(struct, {name, value}) do
    props = struct |> apply(:__message_props__, [])
    props
    |> Map.get(:field_tags)
    |> Map.get(name)
    |> init_property_(name, value, props)
  end

  defp init_property_(_index = nil, name, value, _props), do: {name, value}
  defp init_property_(index, name, value, props) do
    props.field_props[index].repeated?
    |> repeated_or_not(index, name, value, props)
    |> name_and_value(name)
  end

  defp repeated_or_not(_repeated = true, index, name, value, props),
    do: value |> Enum.map(fn value -> do_init(index, name, value, props) end)
  defp repeated_or_not(_repeated = false, index, name, value, props),
    do: do_init(index, name, value, props)

  defp do_init(index, name, value, props) do
    field_type = props.field_props[index].type

    props.field_props[index].enum_type
    |> set_if_enum(name, value)
    |> deep_new(field_type, name)
  end

##########################  H E L P E R S  ##########################

  defp apply_reverse(args, fun, mod), do: apply(mod, fun, [args])

  defp set_if_enum(enum_type, name, value)
    when not is_nil(enum_type) and is_atom(value) do
      enum_type
      |> apply(:__message_props__, [])
      |> enum_atom2int(value, name)
  end
  defp set_if_enum(_enum_type, _name, value), do: value

  defp enum_atom2int(enum_type_props, value, name) do
    case enum_type_props.field_tags[value] do
      nil -> raise "Field '#{name}': not valid enum key: '#{value}'"
      numeric_value -> numeric_value
    end
  end

  defp name_and_value(value, name), do: {name, value}
end
