defmodule FindMeAFlatWeb.HealthControllerTest do
  @moduledoc """
  The load-bearing assertion here is the 503, not the 200.

  A health check that answers 200 whenever the web server is up reports the one
  thing a load balancer can already see for itself. The failure it has to catch is
  the silent one: `queues: false` on the production config path, or the cron plugin
  dropped from the plugin list, where the endpoint answers, the container stays up,
  and no crawl has run for a week.
  """

  # Not `async: true`: the third test takes the Repo away by putting the sandbox
  # back into manual mode, which is global state. ExUnit runs every async test
  # before any sync one, so as a sync case it cannot strand a concurrent test.
  use FindMeAFlatWeb.ConnCase

  alias Ecto.Adapters.SQL.Sandbox
  alias FindMeAFlat.Repo

  describe "GET /healthz" do
    test "returns 200 when the Repo answers and cron enqueued inside the window", %{conn: conn} do
      enqueue_cron_pulse(30)

      conn = get(conn, ~p"/healthz")

      assert %{"status" => "ok", "checks" => %{"database" => true, "cron" => true}} =
               json_response(conn, 200)
    end

    test "returns 503 when the newest cron enqueue is older than the window", %{conn: conn} do
      enqueue_cron_pulse(180)

      conn = get(conn, ~p"/healthz")

      assert %{"status" => "unhealthy", "checks" => %{"database" => true, "cron" => false}} =
               json_response(conn, 503)
    end

    test "returns 503 when the Repo cannot check out a connection", %{conn: conn} do
      # Cron is healthy, so the only thing left to fail is the database.
      enqueue_cron_pulse(30)
      Sandbox.mode(Repo, :manual)

      conn = get(conn, ~p"/healthz")

      assert %{"status" => "unhealthy", "checks" => %{"database" => false}} =
               json_response(conn, 503)
    end
  end

  # Writes the evidence the Cron plugin writes — a job row whose meta carries
  # `"cron" => true` — rather than going through `Oban.insert/1`, because the
  # backdated row the stale case needs cannot be built any other way. Only the
  # columns without a database default are given, so this fixture does not restate
  # Oban's schema and rot against it.
  defp enqueue_cron_pulse(seconds_ago) do
    at = NaiveDateTime.add(NaiveDateTime.utc_now(:second), -seconds_ago, :second)

    Repo.insert_all("oban_jobs", [
      %{
        queue: "maintenance",
        worker: "FindMeAFlat.Maintenance.PulseWorker",
        meta: %{"cron" => true, "cron_expr" => "* * * * *", "cron_tz" => "Etc/UTC"},
        inserted_at: at,
        scheduled_at: at
      }
    ])
  end
end
