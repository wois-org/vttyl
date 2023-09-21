defmodule Vttyl.Decode do
  @moduledoc false

  alias Vttyl.Part

  def parse(enum_content) do
    enum_content
    |> Stream.map(fn line -> Regex.replace(~r/#.*/, line, "") end)
    |> Stream.chunk_while("", &parse_chunk/2, &parse_chunk_after/1)
    |> Stream.map(&to_part/1)
    |> Stream.reject(fn %Part{text: text} -> text == "WEBVTT" end)
  end

  defp parse_chunk(line, acc) do
    (acc <> line)
    |> String.split("\n\n")
    |> case do
      [prev, next] -> {:cont, prev, next}
      [prev] -> {:cont, prev}
    end
  end

  defp parse_chunk_after(acc) do
    acc
    |> String.split("\n\n")
    |> case do
      [prev, next] -> {:cont, prev, next}
      [prev] -> {:cont, prev, ""}
    end
  end

  defp to_part(part_string) do
    part_string
    |> String.split("\n")
    |> Enum.reduce(%Part{}, fn line, acc ->
      cond do
        part?(line) ->
          %Part{acc | part: String.to_integer(line)}

        timestamps?(line) ->
          {start_ts, end_ts} = parse_timestamps(line)
          %Part{acc | start: start_ts, end: end_ts}

        line != "" ->
          {voice, text} = parse_line(line, acc.text)

          %Part{acc | text: text, voice: voice}

        true ->
          acc
      end
    end)
  end

  @ts_pattern ~S"(?:(\d{2,}):)?(\d{2}):(\d{2})\.(\d{3})"
  @line_regex ~r/#{@ts_pattern} --> #{@ts_pattern}/
  @ts_regex ~r/#{@ts_pattern}/

  defp part?(line) do
    Regex.match?(~r/^\d+$/, line)
  end

  # 00:00:00.000 --> 00:01:01.000
  defp timestamps?(line) do
    Regex.match?(@line_regex, line)
  end

  @annotation_space_regex ~r/[ \t]/
  defp parse_line("<v" <> line, acc_text) do
    [voice, text] = String.split(line, ">", parts: 2)
    [_, voice] = String.split(voice, @annotation_space_regex, parts: 2)

    {voice, text |> parse_text(acc_text)}
  end

  defp parse_line(line, acc_text) do
    {nil, line |> parse_text(acc_text)}
  end

  defp parse_text(text, acc_text) when acc_text |> is_binary() do
    "#{acc_text}\n #{text}"
  end

  defp parse_text(text, _) do
    text
  end

  defp parse_timestamps(line) do
    line
    |> String.split("-->")
    |> Enum.map(fn ts ->
      ts = String.trim(ts)
      [hour, minute, second, millisecond] = Regex.run(@ts_regex, ts, capture: :all_but_first)

      case hour do
        "" -> 0
        hour -> String.to_integer(hour) * 3_600_000
      end +
        String.to_integer(minute) * 60_000 +
        String.to_integer(second) * 1_000 +
        String.to_integer(millisecond)
    end)
    |> List.to_tuple()
  end
end
