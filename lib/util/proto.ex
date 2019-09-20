defmodule Util.Proto do
  @moduledoc """
  This module is intended as a simple way for initializing deeply nested Protobuf
  structures defined by protobuf-elixir modules.

  Usage:
    iex> Util.Proto.deep_new!(arguments, module, options)
    - arguments - [required] Plain elixir map with actual values for stucture fields
    - module    - [required] Name of module which contains Protobuf structure definition
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
     two parameters, field_name and field_values and returne new field_values.
     While parsing arguments given to deep_new, whenever a field with non-basic
     type is processed, if it's type is a key in 'transformations' map, a function
     provided as a value for that key will be called before initializing field
     with field's name and field's values as parameters.
     This is convenient way to manually transform fields stored in one format to
     another one used in Protobuf structure without need to iterate trough all
    nested structures and perform transforamtions before calling 'deep_new'.
     E.g. transform every Ecto.DateTime field into Google.Protobuf.Timestamp
  """

  @proto_basic_types ~w(bool string enum int32 int64 uint32 uint64 sint32 sint64
   fixed32 fixed64 sfixed32 sfixed64 float double)a

  def deep_new(_, _, opts \\ [])

  def deep_new(args, struct, opts) when is_atom(struct) and is_map(args) do
    deep_new(struct, args, opts)
  end

  def deep_new(struct, args, opts) do
    {:ok, deep_new!(struct, args, opts)}
  rescue
    e ->
      {:error, e}
  end

  def deep_new!(_, _, opts \\ [])

  def deep_new!(args, struct, opts) when is_atom(struct) and is_map(args) do
    deep_new!(struct, args, opts)
  end

  def deep_new!(struct, args, opts), do: do_deep_new(args, struct, "", opts)


######################

  @doc """
  Transforms proto message struct into elixir map and transforms values for all
  enum fields into atoms instead of integers.

  Usage:
    iex> Util.Proto.to_map!(proto_struct, options)
    - proto_struct - [required] Proto struct which should be transformed into plain map
    - options      - [optional] Keyword containing optional parameters. More details below.

  Options filed parameters:
  - string_keys:
      If this parameter i set to true resulting map will have string keys instead
      of atom key, which is default behavior
  - transformations:
      Map where keys should be module names, and values user provided
      functions, given either as annonymous functions or tuple
      in form {module_name, fun_name}. This functions should receive
      two parameters, field_name and field_values, and return new filed_values.
      While parsing struct given to 'to_map', whenever a field with non-basic
      type is processed, if it's type is a key in 'transformations' map, a function
      provided as a value for that key will be called  with field's name and field's
      values as parameters.
      This is convinient way to manually transform fields received in one format
      in Protobuf structure to another one used  fore storing without needing to
      iterate trough all nested structures and perform transforamtions after
      calling 'to_map'.
      E.g. transform every Google.Protobuf.Timestamp field into Ecto.DateTime
  """
  def to_map(proto, opts \\ []) do
    {:ok, to_map!(proto, opts)}
  rescue
    e -> {:error, e}
  end

  def to_map!(proto, opts \\ [])
  def to_map!(proto = %{__struct__: _}, opts), do: decode_value(proto, "", opts)
  def to_map!(proto, _opts), do: raise("Not a valid Proto struct: #{inspect proto}")

  defp decode_value(%struct{} = value, name, opts) do
    case get_user_func(struct, opts) do
      :skip         -> regular_struct_decode(value, name, opts)
      {module, fun} -> apply(module, fun, [name, value])
      fun           -> apply(fun, [name, value])
    end
  end
  defp decode_value(%{} = value, name, opts),
    do: value |> Map.to_list |> decode_value(name, opts) |> Enum.into(%{})
  defp decode_value(value, name, opts) when is_list(value),
    do: Enum.map(value, &decode_value(&1, name, opts))
  defp decode_value({key, value}, _name, opts),
    do: {to_string?(key, opts), decode_value(value, key, opts)}
  defp decode_value(value, _name, _opts),  do: value

  defp regular_struct_decode(%struct{} = value, name, opts) do
    decoded_value = value |> Map.from_struct |> decode_value(name, opts)

    struct.__message_props__.field_props
    |> Enum.reduce(%{}, &decode_enum_value(&1, &2, decoded_value, opts))
  end

  defp decode_enum_value({_k, %{enum?: true, repeated?: true} = props}, acc, decoded_value, opts) do
    field_name = to_string?(props.name_atom, opts)
    decoded_value[field_name]
    |> Enum.map(fn enum_val ->
      enum_val_transformation(props, opts, field_name, enum_val)
    end)
    |> map_put_reverse(field_name, acc)
  end
  defp decode_enum_value({_k, %{enum?: true} = props}, acc, decoded_value, opts) do
    field_name = to_string?(props.name_atom, opts)
    props
    |> enum_val_transformation(opts, field_name, decoded_value[field_name])
    |> map_put_reverse(field_name, acc)
  end
  defp decode_enum_value({_k, props}, acc, decoded_value, opts) do
    field_name = to_string?(props.name_atom, opts)
    Map.put(acc, field_name, decoded_value[field_name])
  end

  defp enum_val_transformation(props, opts, field_name, enum_val) do
    props
    |> Map.get(:enum_type)
    |> get_user_func(opts)
    |> case do
        :skip ->
          apply(props.enum_type, :key, [enum_val])

        {module, fun} ->
          module |> apply(fun, [field_name, enum_val])

        fun ->
          fun |> apply([field_name, enum_val])
      end
  end

  defp map_put_reverse(value, key, map) do
    Map.put(map, key, value)
  end

  defp to_string?(key, [string_keys: true]), do: Atom.to_string(key)
  defp to_string?(key, _opts), do: key

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
  defp set_enum_value(value, _enum_type, _name) when is_integer(value), do: value

  defp enum_atom2int(enum_type_props, value, name) do
    case enum_type_props.field_tags[value] do
      nil -> raise "Field '#{name}': not valid enum key: '#{value}'"
      numeric_value -> numeric_value
    end
  end

  defp name_and_value(value, name), do: {name, value}
end
