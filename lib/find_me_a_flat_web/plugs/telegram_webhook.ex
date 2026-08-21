defmodule FindMeAFlatWeb.Plugs.TelegramWebhook do
  @moduledoc """
  Verifies that an incoming update really came from Telegram.

  Empty in S1; S5 implements the comparison of `X-Telegram-Bot-Api-Secret-Token`
  against `:telegram_webhook_secret` in constant time, and the router mounts it
  then. Until it does the plug refuses every request, because the webhook is the
  only unauthenticated route in this application and a plug that quietly passes
  everything through would be worse than no plug at all.
  """

  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    conn
    |> Plug.Conn.send_resp(:not_implemented, "")
    |> Plug.Conn.halt()
  end
end
