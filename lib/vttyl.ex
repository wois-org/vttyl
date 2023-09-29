defmodule Vttyl do
  @moduledoc """
  Encoding and decoding VTT files
  """

  alias Vttyl.{Encode, Decode, Part}

  @doc """
  Parse a string.

  This drops badly formatted vtt files.

  This returns a stream so you decide how to handle it!
  """
  @doc since: "0.1.0"
  @spec parse(String.t()) :: Enumerable.t()
  def parse(content) do
    Regex.split(~r"\n\n", content, include_captures: true)
    |> Decode.parse()
  end

  @doc """
  Parse a stream of utf8 encoded characters.

  This returns a stream so you decide how to handle it!
  """
  @doc since: "0.1.0"
  @spec parse_stream(Enumerable.t()) :: Enumerable.t()
  def parse_stream(content) do
    content
    |> Stream.transform("", &next_part/2)
    |> Decode.parse()
  end

  defp next_part(chunk, acc) do
    chunk = <<acc::binary, chunk::binary>> |> String.replace("\r\n", "\n")

    Regex.split(~r"\n\n", chunk, include_captures: true)
    |> case do
      [] ->
        {[], ""}

      parts ->
        # {acc, lines} = List.pop_at(lines, -1) |> IO.inspect()
        {parts, acc}
    end
  end

  @doc """
  Encodes a list of parts into a vtt file.
  """
  @doc since: "0.4.0"
  @spec encode_vtt([Part.t()], [term]) :: String.t()
  def encode_vtt(parts, opts \\ []) do
    opts = opts |> Keyword.put(:type, :vtt)
    Enum.join(["WEBVTT" | Enum.map(parts, &Encode.encode_part(&1, opts))], "\n\n") <> "\n"
  end

  @doc """
  Encodes a list of parts into a srt file.
  """
  @doc since: "0.4.0"
  @spec encode_srt([Part.t()], [term]) :: String.t()
  def encode_srt(parts, opts \\ []) do
    opts = opts |> Keyword.put(:type, :srt)

    Enum.map(parts, &Encode.encode_part(&1, opts))
    |> Enum.join("\n\n")
    |> Kernel.<>("\n")
  end

  @doc """
  Encodes a list of parts into a vtt file.

  This is currently deprecated use encode_vtt/1 or encode_srt/1 instead
  """
  @doc since: "0.3.0"
  @spec encode([Part.t()], [term]) :: String.t()
  def encode(parts, opts \\ []) do
    opts = opts |> Keyword.put(:type, :srt)
    Enum.join(["WEBVTT" | Enum.map(parts, &Encode.encode_part(&1, opts))], "\n\n") <> "\n"
  end
end
