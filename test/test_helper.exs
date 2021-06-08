ExUnit.start(trace: true)

defmodule TestHelpers do

  defmodule SimpleProto do
    use Protobuf, syntax: :proto3

    @type t :: %__MODULE__{
      int_value:     integer,
      string_value:  String.t,
      bool_value:    boolean,
      float_value:   float,
      repeated_string: [String.t]
    }
    defstruct [:int_value, :string_value, :bool_value, :float_value, :repeated_string]

    field :int_value, 1, type: :int32
    field :string_value, 2, type: :string
    field :bool_value, 3, type: :bool
    field :float_value, 4, type: :float
    field :repeated_string, 5, repeated: true, type: :string
  end

  defmodule NestedProto do
    use Protobuf, syntax: :proto3

    @type t :: %__MODULE__{
      simple_proto:  TestHelpers.SimpleProto.t,
      rsp: [TestHelpers.SimpleProto.t]
    }
    defstruct [:simple_proto, :rsp]

    field :simple_proto, 1, type: TestHelpers.SimpleProto
    field :rsp, 2, repeated: true, type: TestHelpers.SimpleProto
  end

  defmodule EnumProto do
    use Protobuf, syntax: :proto3

    @type t :: %__MODULE__{
      code:  integer,
      codes: [integer]
    }
    defstruct [:code, :codes]

    field :code, 1, type: TestHelpers.EnumProto.Code, enum: true
    field :codes, 2, repeated: true, type: TestHelpers.EnumProto.Code, enum: true
  end

  # Mock library has issues with reseting mocks so it is better to use duplicated module
  defmodule EnumProto2 do
    use Protobuf, syntax: :proto3

    @type t :: %__MODULE__{
      code:  integer,
      codes: [integer]
    }
    defstruct [:code, :codes]

    field :code, 1, type: TestHelpers.EnumProto.Code, enum: true
    field :codes, 2, repeated: true, type: TestHelpers.EnumProto.Code, enum: true
  end

  defmodule EnumProto.Code do
    use Protobuf, enum: true, syntax: :proto3

    field :OK, 0
    field :Error, 1
    field :Ambiguous, 2
  end

  defmodule NestedEnumProto do
    use Protobuf, syntax: :proto3

    @type t :: %__MODULE__{
      enum_message:  TestHelpers.EnumProto.t,
      string_val: String.t
    }
    defstruct [:enum_message, :string_val]

    field :enum_message, 1, type: TestHelpers.EnumProto
    field :string_val, 2, repeated: false, type: :string
  end

end
