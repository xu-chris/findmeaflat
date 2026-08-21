defmodule FindMeAFlat.Maintenance.PulseWorker do
  @moduledoc """
  A no-op job enqueued by cron every minute, so that the scheduler leaves evidence.

  `GET /healthz` reports healthy only when a cron enqueue landed within the last
  two minutes. Without a job on the crontab from the very first deploy, a queues- or
  plugin-misconfiguration would look exactly like a working system: the endpoint
  would answer, the container would stay up, and nothing would ever run.

  S14 builds the dead-man ping and the operator digest on top of this queue; the
  pulse itself stays trivial on purpose, because a heartbeat that can fail for its
  own reasons stops being a heartbeat.
  """

  use Oban.Worker, queue: :maintenance, max_attempts: 1

  @doc """
  Performs the pulse. The evidence is the enqueued row, so there is nothing to do.
  """
  @impl Oban.Worker
  def perform(%Oban.Job{}), do: :ok
end
