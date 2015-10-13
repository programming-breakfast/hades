defmodule Hades.SoulView do
  use Hades.Web, :view

  def uptime(created_at) do
    if created_at do
      Timex.Date.diff(created_at, Timex.Date.now(), :timestamp)
      |> Timex.Format.Time.Formatters.Humanized.format
      |> String.split(",", trim: true)
      |> hd
    else
      ""
    end
  end
end
