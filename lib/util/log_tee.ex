defmodule Util.LogTee do
  require Logger

  defmacro tee_(item, tag, severity) do
    quote do
      Logger.unquote(severity)( "#{unquote(tag)}: #{inspect unquote(item)}")
      unquote(item)
    end
  end

  def debug(item, tag) when is_binary(tag), do: tee_(item, tag, :debug)
  def info(item,  tag) when is_binary(tag), do: tee_(item, tag, :info)
  def warn(item,  tag) when is_binary(tag), do: tee_(item, tag, :warn)
  def error(item, tag) when is_binary(tag), do: tee_(item, tag, :error)
end
