defmodule FindMeAFlat.Fetching.PortalGate do
  @moduledoc """
  One process per portal, holding the earliest moment that portal may be asked
  again. It answers yes or no. It never makes anybody wait.

  That is the whole design, and the obvious alternative is the wrong one. A gate
  that blocked the caller until the portal was due would, with twenty watches due on
  one portal and a 30-second pace, park ten Oban jobs for up to 100 seconds each
  **while each of them holds a database connection**. The queue's remaining slots go
  to the portal that is least available, every other portal starves behind it, and
  in a small pool the Telegram webhook starves too. Oban OSS has per-queue
  concurrency but no per-key rate limiting, which is why this is a process at all
  rather than queue configuration.

  So a caller that is too early gets `{:error, :gated, ms}` immediately and the job
  snoozes for that long. Shedding is cheap, retrying is scheduled, and the portal
  still sees a bounded request rate.

  The fetch itself happens in the *calling* process. The gate hands out permission
  and returns; it never touches the network, so its mailbox cannot grow behind a
  slow portal.

  Pacing carries jitter of a tenth of the interval, so a portal is not asked on a
  metronome.
  """

  use GenServer

  # Named, not aliased: this is the name a Registry process runs under, not a module.
  @registry FindMeAFlat.Fetching.Registry

  # The gate does no I/O, so a call that takes seconds means the process is wedged.
  # Left generous anyway: a timeout here is a bug report, not a pacing decision.
  @call_timeout to_timeout(second: 5)

  @doc """
  Starts a gate for one portal. `opts` takes `:slug` and `:min_seconds`.
  """
  def start_link(opts) do
    slug = Keyword.fetch!(opts, :slug)
    GenServer.start_link(__MODULE__, opts, name: via(slug))
  end

  @doc """
  Asks to fetch `slug` now.

  Returns `:ok` when the portal is due, or `{:error, :gated, ms}` with the wait the
  caller should snooze for. Raises when no gate exists: a slug nobody paced is a
  configuration error, not something a portal did.
  """
  @spec request(String.t()) :: :ok | {:error, :gated, pos_integer()}
  def request(slug) do
    case Registry.lookup(@registry, {:portal_gate, slug}) do
      [{pid, _value}] ->
        GenServer.call(pid, :request, @call_timeout)

      [] ->
        raise ArgumentError,
              "no gate is pacing #{inspect(slug)}. Portals hands Fetching its " <>
                "{slug, min_seconds_between_requests} list once at boot, through " <>
                "FindMeAFlat.Fetching.pace/1."
    end
  end

  @doc """
  Sets this portal's minimum interval, starting its gate if it has none.

  Idempotent on purpose: re-pacing an existing portal adjusts the interval and
  keeps the history, so a boot that re-reads the portal rows cannot hand every
  portal a free request.
  """
  @spec pace(String.t(), non_neg_integer()) :: :ok
  def pace(slug, min_seconds) do
    spec = {__MODULE__, slug: slug, min_seconds: min_seconds}

    case DynamicSupervisor.start_child(FindMeAFlat.Fetching.GateSupervisor, spec) do
      {:ok, _pid} ->
        :ok

      {:error, {:already_started, pid}} ->
        GenServer.call(pid, {:pace, min_seconds}, @call_timeout)
    end
  end

  @impl GenServer
  def init(opts) do
    min_ms = to_timeout(second: Keyword.fetch!(opts, :min_seconds))

    # Due now. Monotonic time starts at an arbitrary, often negative, value, so a
    # literal zero here would shed the very first request on a freshly booted node.
    now = System.monotonic_time(:millisecond)

    {:ok, %{slug: Keyword.fetch!(opts, :slug), min_ms: min_ms, next_allowed_at: now}}
  end

  @impl GenServer
  def handle_call(:request, _from, %{next_allowed_at: next} = state) do
    answer(state, System.monotonic_time(:millisecond), next)
  end

  @impl GenServer
  def handle_call({:pace, min_seconds}, _from, state) do
    {:reply, :ok, %{state | min_ms: to_timeout(second: min_seconds)}}
  end

  defp answer(state, now, next) when now >= next do
    {:reply, :ok, %{state | next_allowed_at: now + state.min_ms + jitter(state.min_ms)}}
  end

  defp answer(state, now, next), do: {:reply, {:error, :gated, next - now}, state}

  defp jitter(min_ms) when min_ms < 10, do: 0
  defp jitter(min_ms), do: :rand.uniform(div(min_ms, 10))

  defp via(slug), do: {:via, Registry, {@registry, {:portal_gate, slug}}}
end
