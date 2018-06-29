defmodule Util.ProtoTest do

  use ExUnit.Case

  alias TestHelpers.{SimpleProto, NestedProto, EnumProto}


  test "simple test - no args" do
    assert Util.Proto.deep_new(SimpleProto, %{}) ==
      %TestHelpers.SimpleProto{bool_value: false, int_value: 0, string_value: "",
        float_value: 0, repeated_string: []}
  end

  test "simple test - bool arg" do
    assert Util.Proto.deep_new(SimpleProto, %{bool_value: true}) ==
      %TestHelpers.SimpleProto{bool_value: true, int_value: 0, string_value: "",
        float_value: 0, repeated_string: []}
  end

  test "simple test - int arg" do
    assert Util.Proto.deep_new(SimpleProto, %{int_value: 2}) ==
      %TestHelpers.SimpleProto{bool_value: false, int_value: 2, string_value: "",
      float_value: 0, repeated_string: []}
  end

  test "simple test - float arg" do
    assert Util.Proto.deep_new(SimpleProto, %{float_value: 2.34}) ==
      %TestHelpers.SimpleProto{bool_value: false, int_value: 0, string_value: "",
      float_value: 2.34, repeated_string: []}
  end

  test "simple test - string arg" do
    assert Util.Proto.deep_new(SimpleProto, %{string_value: "2"}) ==
      %TestHelpers.SimpleProto{bool_value: false, int_value: 0, string_value: "2",
      float_value: 0, repeated_string: []}
  end

  test "simple test - repeated field - 0 elements" do
    assert Util.Proto.deep_new(SimpleProto, %{repeated_string: []}) ==
    %TestHelpers.SimpleProto{bool_value: false, int_value: 0, string_value: "",
    float_value: 0, repeated_string: []}
  end

  test "simple test - repeated field - 1 element" do
    assert Util.Proto.deep_new(SimpleProto, %{repeated_string: ["as"]}) ==
    %TestHelpers.SimpleProto{bool_value: false, int_value: 0, string_value: "",
    float_value: 0, repeated_string: ["as"]}
  end

  test "simple test - repeated field - 2 elements" do
    assert Util.Proto.deep_new(SimpleProto, %{repeated_string: ["as", "qw"]}) ==
    %TestHelpers.SimpleProto{bool_value: false, int_value: 0, string_value: "",
    float_value: 0, repeated_string: ["as", "qw"]}
  end


  test "nested test - SimpleProto field - empty map, empty list" do
    assert %TestHelpers.NestedProto{simple_proto: simple_proto, rsp: rsp} =
      Util.Proto.deep_new(NestedProto, %{simple_proto: %{}})

    assert simple_proto == %TestHelpers.SimpleProto{
      bool_value: false, int_value: 0, string_value: "", float_value: 0, repeated_string: []}
    assert rsp == []
  end

  test "nested test - SimpleProto field - non empty map, non empty list" do
    assert %TestHelpers.NestedProto{simple_proto: simple_proto, rsp: rsp} =
      Util.Proto.deep_new(
        NestedProto, %{simple_proto: %{int_value: 3}, rsp: [%{bool_value: true}]})

    assert simple_proto == %TestHelpers.SimpleProto{
      bool_value: false, int_value: 3, string_value: "", float_value: 0, repeated_string: []}
    assert rsp == [%TestHelpers.SimpleProto{
      bool_value: true, int_value: 0, string_value: "", float_value: 0, repeated_string: []}]
  end

  test "enum - no args" do
    assert Util.Proto.deep_new(EnumProto, %{}) == %TestHelpers.EnumProto{code: 0, codes: []}
  end

  test "enum - code" do
    assert Util.Proto.deep_new(EnumProto, %{code: :Error}) == %TestHelpers.EnumProto{code: 1, codes: []}
  end

  test "enum - codes" do
    assert Util.Proto.deep_new(EnumProto, %{codes: [:Error, :OK]}) == %TestHelpers.EnumProto{code: 0, codes: [1, 0]}
  end
end
