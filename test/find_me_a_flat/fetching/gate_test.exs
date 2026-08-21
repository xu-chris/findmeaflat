defmodule FindMeAFlat.Fetching.GateTest do
  @moduledoc """
  The gate sheds. It never parks the caller, and that is the whole point of it.

  A blocking `GenServer.call` would be the obvious way to pace a portal, and it is
  the wrong one here. Twenty due watches on one portal would park ten Oban jobs for
  up to 100 seconds each **while they hold database connections** — head-of-line
  blocking that starves every other portal and can starve the Telegram webhook. So
  the assertions below are as much about elapsed wall-clock as about return values:
  a shed that takes a second is not a shed.
  """

  use ExUnit.Case, async: true

  alias FindMeAFlat.Fetching
  alias FindMeAFlat.Fetching.Page
  alias FindMeAFlat.Fetching.Transport.Stub

  # The stub's /slow route holds a fetch open for a full second. Anything the gate
  # answers has to come back in a small fraction of that, or it queued behind it.
  @shed_budget_ms 200

  setup context do
    %{slug: "gate-#{:erlang.phash2(context.test)}"}
  end

  test "the first caller through a fresh gate is let through", %{slug: slug} do
    :ok = Fetching.pace([{slug, 60}])

    assert {:ok, %Page{}} = Fetching.fetch(slug, url("/ok"))
  end

  test "a second caller inside the interval is shed, with the wait it should snooze for",
       %{slug: slug} do
    :ok = Fetching.pace([{slug, 60}])
    assert {:ok, %Page{}} = Fetching.fetch(slug, url("/ok"))

    {elapsed_us, result} = :timer.tc(fn -> Fetching.fetch(slug, url("/ok")) end)

    assert {:error, :gated, wait_ms} = result
    assert wait_ms > 0
    assert wait_ms <= 66_000
    assert div(elapsed_us, 1000) < @shed_budget_ms
  end

  test "a caller is shed immediately while another caller's fetch is still in flight",
       %{slug: slug} do
    # This is the head-of-line test. If the gate performed the fetch, or held the
    # second caller until the first finished, the shed below would take a second.
    :ok = Fetching.pace([{slug, 60}])
    slow = Task.async(fn -> Fetching.fetch(slug, url("/slow")) end)
    # The stub tells us when it has the request in hand, so the token is provably
    # already spent and the measurement below is of a shed, not of a race.
    assert_receive {:stub, :fetch_started, "/slow"}, 1_000

    {elapsed_us, result} = :timer.tc(fn -> Fetching.fetch(slug, url("/ok")) end)

    assert {:error, :gated, _wait_ms} = result
    assert div(elapsed_us, 1000) < @shed_budget_ms
    assert {:ok, %Page{}} = Task.await(slow, 5_000)
  end

  test "twenty due watches on one portal produce one fetch and nineteen sheds", %{slug: slug} do
    :ok = Fetching.pace([{slug, 60}])

    {elapsed_us, results} =
      :timer.tc(fn ->
        1..20
        |> Task.async_stream(fn _ -> Fetching.fetch(slug, url("/ok")) end,
          max_concurrency: 20,
          timeout: 5_000
        )
        |> Enum.map(fn {:ok, result} -> result end)
      end)

    assert Enum.count(results, &match?({:ok, %Page{}}, &1)) == 1
    assert Enum.count(results, &match?({:error, :gated, _}, &1)) == 19
    assert div(elapsed_us, 1000) < 1_000
  end

  test "the shed carries a hint a worker can snooze on", %{slug: slug} do
    :ok = Fetching.pace([{slug, 60}])
    assert {:ok, %Page{}} = Fetching.fetch(slug, url("/ok"))

    assert {:error, :gated, _} = shed = Fetching.fetch(slug, url("/ok"))
    assert {:snooze, seconds} = Fetching.disposition(shed)
    assert seconds > 0
    assert seconds <= 66
  end

  test "a portal whose interval has elapsed is let through again", %{slug: slug} do
    :ok = Fetching.pace([{slug, 0}])

    assert {:ok, %Page{}} = Fetching.fetch(slug, url("/ok"))
    assert {:ok, %Page{}} = Fetching.fetch(slug, url("/ok"))
  end

  test "one portal's gate does not pace another portal", %{slug: slug} do
    other = "#{slug}-neighbour"
    :ok = Fetching.pace([{slug, 60}, {other, 60}])

    assert {:ok, %Page{}} = Fetching.fetch(slug, url("/ok"))
    assert {:error, :gated, _} = Fetching.fetch(slug, url("/ok"))
    assert {:ok, %Page{}} = Fetching.fetch(other, url("/ok"))
  end

  test "pacing the same portal twice re-uses its gate rather than losing its history",
       %{slug: slug} do
    :ok = Fetching.pace([{slug, 60}])
    assert {:ok, %Page{}} = Fetching.fetch(slug, url("/ok"))

    :ok = Fetching.pace([{slug, 90}])

    assert {:error, :gated, _} = Fetching.fetch(slug, url("/ok"))
  end

  test "fetching a portal nobody paced is a configuration error, not an outcome" do
    assert_raise ArgumentError, ~r/never-paced/, fn ->
      Fetching.fetch("never-paced", url("/ok"))
    end
  end

  defp url(path), do: Stub.host() <> path
end
