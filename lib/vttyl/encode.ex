defmodule Vttyl.Encode do
  @moduledoc false
  alias Vttyl.Part

  @spec encode_part(Part.t(), keyword) :: String.t()
  def encode_part(part, opts \\ []) do
    type = opts |> Keyword.get(:type)

    ts = fmt_timestamp(part.start, opts) <> " --> " <> fmt_timestamp(part.end, opts)

    text =
      if type == :vtt && part.voice do
        "<v #{part.voice}>" <> part.text
      else
        part.text
      end

    {type, part.part}
    |> case do
      {:vtt, nil} -> Enum.join([ts, text], "\n")
      {_, pt} -> Enum.join([pt, ts, text], "\n")
    end
  end

  @hour_ms 3_600_000
  @minute_ms 60_000
  defp fmt_timestamp(milliseconds, opts) do
    type = opts |> Keyword.get(:type)
    force_ts_hours = opts |> Keyword.get(:force_ts_hours, false)
    {hours, ms_wo_hrs} = mod(milliseconds, @hour_ms)
    {minutes, ms_wo_mins} = mod(ms_wo_hrs, @minute_ms)

    # Lop off hours if there aren't any
    hr_and_min =
      if hours <= 0 and type == :vtt and !force_ts_hours do
        prefix_fmt(minutes)
      else
        [hours, minutes]
        |> Enum.map(&prefix_fmt/1)
        |> Enum.join(":")
      end

    hr_and_min <> ":" <> fmt_seconds(ms_wo_mins, type)
  end

  defp mod(dividend, divisor) do
    remainder = Integer.mod(dividend, divisor)
    quotient = (dividend - remainder) / divisor
    {trunc(quotient), remainder}
  end

  defp prefix_fmt(num) do
    num |> Integer.to_string() |> String.pad_leading(2, "0")
  end

  # Force seconds to have three decimal places and 0 padded in the front
  @second_ms 1000
  defp fmt_seconds(milliseconds, type) do
    [seconds, dec_part] =
      milliseconds
      |> Kernel./(@second_ms)
      |> Float.round(3)
      |> Float.to_string()
      |> String.split(".")

    seconds = String.pad_leading(seconds, 2, "0")
    ms_part = String.pad_trailing(dec_part, 3, "0")

    separator =
      if type == :srt do
        ","
      else
        "."
      end

    seconds <> separator <> ms_part
  end
end
