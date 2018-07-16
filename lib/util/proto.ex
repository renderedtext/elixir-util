defmodule Util.Proto do
  @moduledoc """
  This module is inteded as a simple way for initializing deeply nested Protobuf
  structures defined by protobuf-elixir modules.

  Usage:
    iex> Util.Proto.deep_new!(module, arguments, options)
    - module    - [required] Name of module which contains Protobuf structure definition
    - arguments - [required] Plain elixir map with actual values for stucture fields
    - options   - [optional] Keyword containing optional parameters. More details below.

  Function will iterate ower passed arguments, recursively initialize any non-basic
  type fields and than call given module's `new` function with properly initialized
  parameters.

  Options filed parameters:
  - string_keys_to_atoms:
    If value of this field is true, any Map key which is string in passed arguments
    map and all nested maps will be automatically transformed into atom.
  - transformations:
     Map where keys should be module names, and values user provided
     functions, given either as annonymous functions or tuple
     in form {module_name, fun_name}. This functions should receive
     two parameters, field_name and field_values and returne new filed_values.
     While parsing arguments given to deep_new, whenever a field with non-basic
     type is processed, if it's type is a key in 'transformations' map, a function
     provided as a value for that key will be called before initilaizing filed
     with field's name and field's values as parameters.
     This is convinient way to manually transform fields stored in one format to
     another one used in Protobuf structure without needing to iterate trough all
    nested structures and perform transforamtions before calling 'deep_new'.
     E.g. transform every Ecto.DateTime field into Google.Protobuf.Timestamp
  """

  @proto_basic_types ~w(bool string enum int32 int64 uint32 uint64 sint32 sint64
   fixed32 fixed64 sfixed32 sfixed64 float double)a

  def deep_new(struct, args, opts \\ []) do
    {:ok, deep_new!(struct, args, opts)}
  rescue
    e ->
      {:error, e}
  end

  def deep_new!(struct, args, opts \\ []), do: do_deep_new(args, struct, "", opts)

  def to_map(proto) do
    {:ok, to_map!(proto)}
  rescue
    e -> {:error, e}
  end

  def to_map!(proto), do: decode_value(proto)


  defp decode_value(%_{} = value), do: value |> Map.from_struct |> decode_value
  defp decode_value(%{} = value),  do: value |> Map.to_list     |> decode_value |> Enum.into(%{})
  defp decode_value(value) when is_list(value), do: Enum.map(value, &decode_value(&1))
  defp decode_value({key, value}), do: {key, decode_value(value)}
  defp decode_value(value),        do: value

  defp l(v, label), do: IO.inspect(v, label: label)

######################

  defp do_deep_new(args, struct, name, opts)
    when (is_list(args) or is_map(args) or is_nil(args))
          and (not struct in @proto_basic_types) do
      args
      |> user_func_or_init_args(struct, name, opts)
      |> apply_reverse(:new, struct)
  end

  defp do_deep_new(arg, _struct = :bool, _name, _opts) when is_boolean(arg), do: arg
  defp do_deep_new(arg, _struct = :bool, name, _opts),
    do: raise "Field: '#{name}': Expected boolean argument, got '#{inspect arg}'"

  defp do_deep_new(arg, _struct = :string, _name, _opts) when is_binary(arg), do: arg
  defp do_deep_new(arg, _struct = :string, name, _opts),
    do: raise "Field: '#{name}': Expected string argument, got '#{inspect arg}'"

  defp do_deep_new(arg, _struct = :enum, _name, _opts) when is_integer(arg), do: arg
  defp do_deep_new(arg, _struct = :enum, name, _opts),
    do: raise "Field: '#{name}': Expected integer or atom argument, got '#{inspect arg}'"

  defp do_deep_new(arg, struct, _name, _opts)
    when struct in [:int32, :int64, :uint32, :uint64, :sint32, :sint64] and
      is_integer(arg), do: arg
  defp do_deep_new(arg, struct, name, _opts)
    when struct in [:int32, :int64, :uint32, :uint64, :sint32, :sint64],
    do: raise "Field: '#{name}': Expected #{inspect struct} argument, got '#{inspect arg}'"

  defp do_deep_new(arg, struct, _name, _opts)
    when struct in [:fixed32, :fixed64, :sfixed32, :sfixed64, :float, :double] and
      is_float(arg), do: arg
  defp do_deep_new(arg, struct, name, _opts)
    when struct in [:fixed32, :fixed64, :sfixed32, :sfixed64, :float, :double],
    do: raise "Field: '#{name}': Expected #{inspect struct} argument, got '#{inspect arg}'"

  defp user_func_or_init_args(args, struct, name, opts) do
    case get_user_func(struct, opts) do
      :skip         -> init_args(args, struct, name, opts)
      {module, fun} -> apply(module, fun, [name, args])
      fun           -> apply(fun, [name, args])
    end
  end

  defp get_user_func(struct, opts) do
    opts |> Keyword.get(:transformations, %{}) |> Map.get(struct, :skip)
  end

  defp init_args(_args = nil, struct, name, opts) do
    init_property(struct, {name, nil}, opts)
  end
  defp init_args(args, struct, _name, opts) do
    args |> Enum.map(&init_property(struct, &1, opts))
  end

  defp init_property(struct, {name, value}, opts) when is_binary(name)  do
    if Keyword.get(opts, :string_keys_to_atoms, false) do
      init_property(struct, {String.to_atom(name), value}, opts)
    else
      {name, value}
    end
  end
  defp init_property(struct, {name, value}, opts) do
    props = struct |> apply(:__message_props__, [])
    props
    |> Map.get(:field_tags)
    |> Map.get(name)
    |> init_property_(name, value, props, opts)
  end

  defp init_property_(_index = nil, name, value, _props, _opts), do: {name, value}
  defp init_property_(index, name, value, props, opts) do
    props.field_props[index].repeated?
    |> repeated_or_not(index, name, value, props, opts)
    |> name_and_value(name)
  end

  defp repeated_or_not(_repeated = true, _index, _name, nil, _props, _opts), do: []
  defp repeated_or_not(_repeated = true, index, name, values, props, opts),
    do: values |> Enum.map(fn value -> do_init(index, name, value, props, opts) end)
  defp repeated_or_not(_repeated = false, index, name, value, props, opts),
    do: do_init(index, name, value, props, opts)

  defp do_init(index, name, value, props, opts) do
    field_type = props.field_props[index].type

    props.field_props[index].enum_type
    |> set_if_enum(name, value, opts)
    |> do_deep_new(field_type, name, opts)
  end

##########################  H E L P E R S  ##########################

  defp apply_reverse(args, fun, mod), do: apply(mod, fun, [args])

  defp set_if_enum(enum_type, name, value, opts) when not is_nil(enum_type) do
    case get_user_func(enum_type, opts) do
      :skip ->
        set_enum_value(value, enum_type, name)

      {module, fun} ->
        module |> apply(fun, [name, value]) |> set_enum_value(enum_type, name)

      fun ->
        fun |> apply([name, value]) |> set_enum_value(enum_type, name)
    end
  end
  defp set_if_enum(_enum_type, _name, value, _opts), do: value

  defp set_enum_value(value, enum_type, name) when is_atom(value) do
    enum_type
    |> apply(:__message_props__, [])
    |> enum_atom2int(value, name)
  end

  defp enum_atom2int(enum_type_props, value, name) do
    case enum_type_props.field_tags[value] do
      nil -> raise "Field '#{name}': not valid enum key: '#{value}'"
      numeric_value -> numeric_value
    end
  end

  defp name_and_value(value, name), do: {name, value}
end
