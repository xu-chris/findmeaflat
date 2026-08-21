defmodule FindMeAFlat.Fetching.CookieJar do
  @moduledoc """
  One cookie jar per portal, kept for the life of the node.

  Portals hand out a session cookie on the first request and expect it back on the
  next one; a client that drops it looks like a fresh visitor every time, which is
  exactly the shape bot management is built to notice. The Node predecessor could
  not hold a cookie at all.

  The jar is an ETS table this process only owns. Readers and writers touch it
  directly, so a fetch never queues behind another portal's fetch to read its own
  cookies -- the same reason the gate sheds rather than serialising.

  Deliberately simple: name and value, scoped by portal slug, no expiry and no path
  or domain matching. Every portal here is one host and one search URL, and an
  attribute-aware jar would be inventing requirements. A cookie sent with an empty
  value is a deletion and is treated as one.
  """

  use GenServer

  @table __MODULE__

  @doc "Starts the jar. Supervised by `FindMeAFlat.Fetching.Supervisor`."
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Stores whatever a response set. Accepts the header map a `Transport` returns.
  """
  @spec absorb(String.t(), %{String.t() => [String.t()]}) :: :ok
  def absorb(slug, headers) do
    headers
    |> Map.get("set-cookie", [])
    |> Enum.each(&store(slug, &1))
  end

  @doc """
  The `cookie` header value for this portal, or `nil` when its jar is empty.
  """
  @spec cookie_header(String.t()) :: String.t() | nil
  def cookie_header(slug) do
    @table
    |> :ets.match_object({{slug, :_}, :_})
    |> Enum.map_join("; ", fn {{_slug, name}, value} -> "#{name}=#{value}" end)
    |> presence()
  end

  @impl GenServer
  def init(_opts) do
    :ets.new(@table, [
      :named_table,
      :public,
      :set,
      read_concurrency: true,
      write_concurrency: true
    ])

    {:ok, %{}}
  end

  defp store(slug, set_cookie) do
    set_cookie
    |> String.split(";", parts: 2)
    |> hd()
    |> String.split("=", parts: 2)
    |> write(slug)
  end

  defp write([name, value], slug) do
    name = String.trim(name)
    value = String.trim(value)

    case value do
      "" -> :ets.delete(@table, {slug, name})
      _kept -> :ets.insert(@table, {{slug, name}, value})
    end

    :ok
  end

  # A Set-Cookie with no `=` is not a cookie. Ignore it rather than guess.
  defp write(_malformed, _slug), do: :ok

  defp presence(""), do: nil
  defp presence(header), do: header
end
