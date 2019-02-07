defmodule Util.ProtoTest do

  use ExUnit.Case

  alias TestHelpers.{SimpleProto, NestedProto, EnumProto, NestedEnumProto}

  test "simple test - no args - args first" do
    assert %{} |> Util.Proto.deep_new!(SimpleProto) ==
      %SimpleProto{bool_value: false, int_value: 0, string_value: "",
        float_value: 0, repeated_string: []}
  end

  test "simple test - no args" do
    assert Util.Proto.deep_new!(SimpleProto, %{}) ==
      %SimpleProto{bool_value: false, int_value: 0, string_value: "",
        float_value: 0, repeated_string: []}
  end

  test "simple test - bool arg" do
    assert Util.Proto.deep_new!(SimpleProto, %{bool_value: true}) ==
      %TestHelpers.SimpleProto{bool_value: true, int_value: 0, string_value: "",
        float_value: 0, repeated_string: []}
  end

  test "simple test - int arg" do
    assert Util.Proto.deep_new!(SimpleProto, %{int_value: 2}) ==
      %TestHelpers.SimpleProto{bool_value: false, int_value: 2, string_value: "",
      float_value: 0, repeated_string: []}
  end

  test "simple test - float arg" do
    assert Util.Proto.deep_new!(SimpleProto, %{float_value: 2.34}) ==
      %TestHelpers.SimpleProto{bool_value: false, int_value: 0, string_value: "",
      float_value: 2.34, repeated_string: []}
  end

  test "simple test - string arg" do
    assert Util.Proto.deep_new!(SimpleProto, %{string_value: "2"}) ==
      %TestHelpers.SimpleProto{bool_value: false, int_value: 0, string_value: "2",
      float_value: 0, repeated_string: []}
  end

  test "simple test - repeated field - 0 elements" do
    assert Util.Proto.deep_new!(SimpleProto, %{repeated_string: []}) ==
    %TestHelpers.SimpleProto{bool_value: false, int_value: 0, string_value: "",
    float_value: 0, repeated_string: []}
  end

  test "simple test - repeated field - 1 element" do
    assert Util.Proto.deep_new!(SimpleProto, %{repeated_string: ["as"]}) ==
    %TestHelpers.SimpleProto{bool_value: false, int_value: 0, string_value: "",
    float_value: 0, repeated_string: ["as"]}
  end

  test "simple test - repeated field - 2 elements" do
    assert Util.Proto.deep_new!(SimpleProto, %{repeated_string: ["as", "qw"]}) ==
    %TestHelpers.SimpleProto{bool_value: false, int_value: 0, string_value: "",
    float_value: 0, repeated_string: ["as", "qw"]}
  end


  test "nested test - SimpleProto field - empty map, empty list" do
    assert %TestHelpers.NestedProto{simple_proto: simple_proto, rsp: rsp} =
      Util.Proto.deep_new!(NestedProto, %{simple_proto: %{}})

    assert simple_proto == %TestHelpers.SimpleProto{
      bool_value: false, int_value: 0, string_value: "", float_value: 0, repeated_string: []}
    assert rsp == []
  end

  test "nested test - SimpleProto field - non empty map, non empty list - args first" do
    assert %NestedProto{simple_proto: simple_proto, rsp: rsp} =
      %{simple_proto: %{int_value: 3}, rsp: [%{bool_value: true}]}
      |> Util.Proto.deep_new!(NestedProto)

      simple_proto_non_empty_assert(simple_proto, rsp)
  end

  test "nested test - SimpleProto field - non empty map, non empty list" do
    assert %NestedProto{simple_proto: simple_proto, rsp: rsp} =
      Util.Proto.deep_new!(
        NestedProto, %{simple_proto: %{int_value: 3}, rsp: [%{bool_value: true}]})

    simple_proto_non_empty_assert(simple_proto, rsp)
  end

  defp simple_proto_non_empty_assert(simple_proto, rsp) do
    assert simple_proto == %SimpleProto{
      bool_value: false, int_value: 3, string_value: "", float_value: 0, repeated_string: []}
    assert rsp == [%SimpleProto{
      bool_value: true, int_value: 0, string_value: "", float_value: 0, repeated_string: []}]
  end

  test "annonymous user transform function is called" do
    fun =  fn name, _args -> %{int_value: 123, bool_value: true, string_value: name |> to_string()} end

    assert %NestedProto{simple_proto: simple_proto, rsp: rsp} =
      Util.Proto.deep_new!(
         NestedProto,
         %{simple_proto: %{int_value: 3, bool_value: false}, rsp: [%{bool_value: false}]},
         transformations: %{SimpleProto => fun})

     assert simple_proto == %SimpleProto{
       bool_value: true, int_value: 123, string_value: "simple_proto", float_value: 0, repeated_string: []}
     assert rsp == [%SimpleProto{
       bool_value: true, int_value: 123, string_value: "rsp", float_value: 0, repeated_string: []}]
  end

  test "named user transform function is called" do
    assert %NestedProto{simple_proto: simple_proto, rsp: rsp} =
      Util.Proto.deep_new!(
         NestedProto,
         %{simple_proto: %{int_value: 3, bool_value: false}, rsp: [%{bool_value: false}]},
         transformations: %{SimpleProto => {Util.ProtoTest, :named_function}})

     assert simple_proto == %SimpleProto{
       bool_value: true, int_value: 123, string_value: "simple_proto", float_value: 0, repeated_string: []}
     assert rsp == [%SimpleProto{
       bool_value: true, int_value: 123, string_value: "rsp", float_value: 0, repeated_string: []}]
  end

  def named_function(name, _args) do
    %{int_value: 123, bool_value: true, string_value: name |> to_string()}
  end

  test "enum - no args" do
    assert Util.Proto.deep_new!(EnumProto, %{}) == %EnumProto{code: 0, codes: []}
  end

  test "enum - code" do
    assert Util.Proto.deep_new!(EnumProto, %{code: :Error}) == %EnumProto{code: 1, codes: []}
  end

  test "enum - codes" do
    assert Util.Proto.deep_new!(EnumProto, %{codes: [:Error, :OK]}) == %EnumProto{code: 0, codes: [1, 0]}
  end

  test "nested enum - int values" do
    assert Util.Proto.deep_new!(NestedEnumProto, %{enum_message: %{code: 0, codes: [0, 1]}})
           == %NestedEnumProto{enum_message: %EnumProto{code: 0, codes: [0, 1]}, string_val: ""}
  end

  test "nested enum - atom values" do
    assert Util.Proto.deep_new!(NestedEnumProto, %{enum_message: %{code: :Error, codes: [:OK, :Error]}})
           == %NestedEnumProto{enum_message: %EnumProto{code: 1, codes: [0, 1]}, string_val: ""}
  end

  test "{:ok, state}" do
    assert Util.Proto.deep_new(SimpleProto, %{bool_value: true}) ==
      {:ok, %TestHelpers.SimpleProto{bool_value: true, int_value: 0, string_value: "",
        float_value: 0, repeated_string: []}}
  end

  test "{:error, reason}" do
    assert Util.Proto.deep_new(SimpleProto, %{bool_value: 12}) ==
      {:error, %RuntimeError{message: "Field: 'bool_value': Expected boolean argument, got '12'"}}
  end

  test "string_keys_to_atoms" do
    assert %NestedProto{simple_proto: simple_proto, rsp: rsp} =
      Util.Proto.deep_new!(
         NestedProto,
         %{"simple_proto" => %{"int_value" => 3, "bool_value" => true}, "rsp" => [%{string_value: "test"}]},
         string_keys_to_atoms: true)

     assert simple_proto == %SimpleProto{
       bool_value: true, int_value: 3, string_value: "", float_value: 0, repeated_string: []}
     assert rsp == [%SimpleProto{
       bool_value: false, int_value: 0, string_value: "test", float_value: 0, repeated_string: []}]
  end

  test "to_map - error when something other then struct is passed" do
    assert("123" |> Util.Proto.to_map == {:error, %RuntimeError{message: "Not a valid Proto struct: \"123\""}})
  end

  test "EnumProto to_map - no args" do
    assert(TestHelpers.EnumProto.new |> Util.Proto.to_map! == %{code: :OK, codes: []})
  end

  test "EnumProto to_map - code" do
    assert(TestHelpers.EnumProto.new(%{code: 1}) |> Util.Proto.to_map! == %{code: :Error, codes: []})
  end

  test "EnumProto to_map - codes" do
    assert(%{codes: [0, 1, 2]}
           |> Util.Proto.deep_new!(TestHelpers.EnumProto)
           |> Util.Proto.to_map! == %{code: :OK, codes: [:OK, :Error, :Ambiguous]}
    )
  end

  test "SimpleProto to_map" do
    assert(TestHelpers.SimpleProto.new(%{code: 1}) |> Util.Proto.to_map! ==
      %{bool_value: false, float_value: 0.0, int_value: 0, repeated_string: [], string_value: ""}
    )
  end

  test "NestedProto to_map - simple_proto" do
    assert(Util.Proto.deep_new!(TestHelpers.NestedProto, %{simple_proto: %{}}) |> Util.Proto.to_map! ==
      %{rsp: [], simple_proto: %{bool_value: false, float_value: 0.0, int_value: 0, repeated_string: [], string_value: ""}}
    )
  end

  test "NestedProto to_map - repeated simple_proto" do
    sp = %{simple_proto: %{}}
    assert(Util.Proto.deep_new!(TestHelpers.NestedProto, %{rsp: [sp]}) |> Util.Proto.to_map! ==
      %{rsp: [%{bool_value: false, float_value: 0.0, int_value: 0, repeated_string: [], string_value: ""}], simple_proto: nil}
    )
  end

  test "EnumProto to_map string_keys - no args" do
    assert(TestHelpers.EnumProto.new |> Util.Proto.to_map!(string_keys: true)
      == %{"code" => :OK, "codes" => []})
  end

  test "EnumProto to_map string_keys - code" do
    assert(TestHelpers.EnumProto.new(%{code: 1}) |> Util.Proto.to_map!(string_keys: true)
      == %{"code" => :Error, "codes" => []})
  end

  test "EnumProto to_map string_keys - codes" do
    assert(%{codes: [0, 1, 2]}
           |> Util.Proto.deep_new!(TestHelpers.EnumProto)
           |> Util.Proto.to_map!(string_keys: true) ==
      %{"code" => :OK, "codes" => [:OK, :Error, :Ambiguous]}
    )
  end

  test "SimpleProto to_map string_keys" do
    assert(TestHelpers.SimpleProto.new(%{code: 1}) |> Util.Proto.to_map!(string_keys: true) ==
      %{"bool_value" => false, "float_value" => 0.0, "int_value" => 0,
        "repeated_string" => [], "string_value" => ""}
    )
  end

  test "NestedProto to_map string_keys - simple_proto" do
    assert(Util.Proto.deep_new!(TestHelpers.NestedProto, %{simple_proto: %{}})
          |> Util.Proto.to_map!(string_keys: true) ==
      %{"rsp" => [], "simple_proto" => %{"bool_value" => false, "float_value" => 0.0,
        "int_value" => 0, "repeated_string" => [], "string_value" => ""}}
    )
  end

  test "NestedProto to_map string_keys - repeated simple_proto" do
    sp = %{simple_proto: %{}}
    assert(Util.Proto.deep_new!(TestHelpers.NestedProto, %{rsp: [sp]})
           |> Util.Proto.to_map!(string_keys: true) ==
      %{"rsp" => [%{"bool_value" => false, "float_value" => 0.0, "int_value" => 0,
        "repeated_string" => [], "string_value" => ""}], "simple_proto" => nil}
    )
  end

  test "NestedProto to_map transformations - annonymous user transform function" do
    struct = %{simple_proto: %{int_value: 5}, rsp: [%{int_value: 7}, %{int_value: 3}]}
             |> Util.Proto.deep_new!(TestHelpers.NestedProto)
    fun = fn k, v -> if k == :simple_proto, do: v.int_value + 5, else: v.int_value + 3 end

    assert struct |> Util.Proto.to_map!(transformations: %{TestHelpers.SimpleProto => fun})
           == %{simple_proto: 10, rsp: [10, 6]}
  end

  def named_transf_to_map(k, v) do
    if k == :simple_proto, do: v.int_value + 5, else: v.int_value + 3
  end

  test "NestedProto to_map transformations - named user transform function" do
    struct = %{simple_proto: %{int_value: 5}, rsp: [%{int_value: 7}, %{int_value: 3}]}
             |> Util.Proto.deep_new!(TestHelpers.NestedProto)

    tf_map = %{TestHelpers.SimpleProto => {Util.ProtoTest, :named_transf_to_map}}

    assert struct |> Util.Proto.to_map!(transformations: tf_map)
           == %{simple_proto: 10, rsp: [10, 6]}
  end

  test "NestedEnumProto to_map transformations - annonymous user transform function" do
    struct = %{enum_message: %{code: 0, codes: [1, 2]}}
             |> Util.Proto.deep_new!(TestHelpers.NestedEnumProto)
    fun = fn k, v -> if k == :code, do: v + 1, else: v + 2 end

    assert struct |> Util.Proto.to_map!(transformations: %{TestHelpers.EnumProto.Code => fun})
           == %{enum_message: %{code: 1, codes: [3, 4]}, string_val: ""}
  end

  test "NestedEnumProto to_map transformations - named user transform function" do
    struct = %{enum_message: %{code: 0, codes: [1, 2]}}
             |> Util.Proto.deep_new!(TestHelpers.NestedEnumProto)

    tf_map = %{TestHelpers.EnumProto.Code => {Util.ProtoTest, :named_enum_transf_to_map}}

    assert struct |> Util.Proto.to_map!(transformations: tf_map)
           == %{enum_message: %{code: 1, codes: [3, 4]}, string_val: ""}
  end

  def named_enum_transf_to_map(k, v) do
    if k == :code, do: v + 1, else: v + 2
  end
end
