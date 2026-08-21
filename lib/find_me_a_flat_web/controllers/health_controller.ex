defmodule FindMeAFlatWeb.HealthController do
  @moduledoc """
  `GET /healthz`, the one health signal that can say no.

  Healthy means two things, and answering the request is neither of them: the Repo
  hands out a connection, and Oban's cron enqueued a job within the last two
  minutes. Anything else is 503.

  The second condition is the whole point. A crawler whose queues are switched off
  by a typo on the production config path looks byte-identical to a working one
  from the outside — the endpoint answers, the container stays up, and no listing
  is ever delivered. That is the year the predecessor spent dead, and an endpoint
  that reports "the web server is running" would not have caught a day of it.

  Recent cron activity is read from the `oban_jobs` table rather than from Oban's
  runtime state, so an Oban upgrade that reshuffles plugin internals cannot quietly
  turn this check into a constant `true`. `FindMeAFlat.Maintenance.PulseWorker` is
  what fills that table every minute; `config/config.exs` documents why no Pruner
  runs, since the default one would delete the evidence this reads.
  """

  use FindMeAFlatWeb, :controller

  import Ecto.Query, only: [from: 2]

  alias FindMeAFlat.Repo

  # The crontab enqueues the pulse every minute, so two minutes tolerates one
  # missed tick — a slow node, a redeploy — without tolerating a stopped scheduler.
  @cron_window_seconds 120

  @doc """
  Reports 200 when the database answers and cron is still enqueueing, 503 otherwise.

  The body names which half failed, because "503" alone sends the operator to the
  wrong half of the system at the wrong hour.
  """
  def show(conn, _params) do
    checks = %{database: repo_checks_out?(), cron: cron_enqueued_recently?()}

    case checks do
      %{database: true, cron: true} ->
        json(conn, %{status: "ok", checks: checks})

      _degraded ->
        conn
        |> put_status(:service_unavailable)
        |> json(%{status: "unhealthy", checks: checks})
    end
  end

  # Both probes below swallow every failure on purpose. A health check that raises
  # answers 500 with no detail, which tells the operator only that something broke
  # somewhere; these have to survive their own failure to report it.
  defp repo_checks_out? do
    Repo.checkout(fn -> true end)
  rescue
    _error -> false
  catch
    :exit, _reason -> false
  end

  defp cron_enqueued_recently? do
    cutoff = NaiveDateTime.add(NaiveDateTime.utc_now(:second), -@cron_window_seconds, :second)

    Repo.exists?(
      from job in "oban_jobs",
        where: fragment("? ->> 'cron'", job.meta) == "true",
        where: job.inserted_at > type(^cutoff, :naive_datetime)
    )
  rescue
    _error -> false
  catch
    :exit, _reason -> false
  end
end
