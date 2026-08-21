defmodule FindMeAFlat.Bot.Supervisor do
  @moduledoc """
  Supervises the Telegram bot's processes.

  Empty in S1 and started by `FindMeAFlat.Application`. S5 adds the ex_gram
  dispatcher and the command router underneath it. Updates arrive over the webhook
  route, so nothing here polls Telegram.
  """

  use Supervisor

  @doc """
  Starts the bot supervisor. Called by the application supervisor at boot.
  """
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl Supervisor
  def init(_init_arg) do
    Supervisor.init([], strategy: :one_for_one)
  end
end
