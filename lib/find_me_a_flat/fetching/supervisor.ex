defmodule FindMeAFlat.Fetching.Supervisor do
  @moduledoc """
  Supervises the processes that talk to portals.

  It lives here rather than under `FindMeAFlat.Portals` because `Portals` is a
  persistence domain and owns no long-lived processes. What hangs off it:

    * a named `Finch` pool, so connections are reused across a portal's requests
      instead of a fresh TLS handshake announcing us each time;
    * the per-portal cookie jar;
    * a `Registry` naming one gate per portal slug, and the `DynamicSupervisor`
      those gates run under.

  Gates are started on demand, by `FindMeAFlat.Fetching.pace/1`, from the
  `{slug, min_seconds_between_requests}` list `Portals` hands over at boot. They are
  not children of this module directly, because that would mean reading portal rows
  during application start -- before the Repo is necessarily useful -- and would
  point the dependency the wrong way.

  `:rest_for_one`, not `:one_for_one`: the gates are named through the Registry and
  the jar's table is owned by the jar, so a crash in either has to take everything
  downstream of it with it. A gate that outlived its Registry would be a process
  nobody could find.
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
    children = [
      {Finch,
       name: FindMeAFlat.Finch,
       pools: %{
         # HTTP/2 first: a client that offers only HTTP/1.1 while calling itself
         # Chrome has contradicted itself before the first byte of HTML.
         #
         # The connect timeout is here rather than in the transport because Req
         # rejects `:connect_options` alongside a named pool -- connecting belongs
         # to whoever owns the connections.
         default: [
           protocols: [:http2, :http1],
           size: 8,
           count: 1,
           conn_opts: [transport_opts: [timeout: to_timeout(second: 10)]]
         ]
       }},
      FindMeAFlat.Fetching.CookieJar,
      {Registry, keys: :unique, name: FindMeAFlat.Fetching.Registry},
      {DynamicSupervisor, name: FindMeAFlat.Fetching.GateSupervisor, strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
