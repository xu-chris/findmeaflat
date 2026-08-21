defmodule FindMeAFlat.Fetching.Supervisor do
  @moduledoc """
  Supervises the processes that talk to portals.

  Empty in S1 and started by `FindMeAFlat.Application` so the spine is real before
  anything hangs off it. S3 adds the per-portal gate that paces requests and sheds
  load, and it belongs here rather than under `FindMeAFlat.Portals`: `Portals` is a
  persistence domain and owns no long-lived processes.
  """

  use Supervisor

  @doc """
  Starts the fetching supervisor. Called by the application supervisor at boot.
  """
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl Supervisor
  def init(_init_arg) do
    Supervisor.init([], strategy: :one_for_one)
  end
end
