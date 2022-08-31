defmodule Util.LogTeeTest do
  use ExUnit.Case
  alias Util.LogTee

  doctest LogTee

  import ExUnit.CaptureLog

  defmacro log_tee_test(severity) do
    quote do
      f = fn -> LogTee.unquote(severity)(12, "6+6") end
      assert capture_log(f) =~ "[#{unquote(severity)}] "
      assert capture_log(f) =~ " 6+6: 12"
      assert f.() == 12
    end
  end

  test "debug" do log_tee_test(:debug) end
  test "info"  do log_tee_test(:info) end
  test "warn"  do log_tee_test(:warn) end
  test "error" do log_tee_test(:error) end
end
