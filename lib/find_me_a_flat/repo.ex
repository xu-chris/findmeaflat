defmodule FindMeAFlat.Repo do
  use AshPostgres.Repo,
    otp_app: :find_me_a_flat

  @impl true
  def installed_extensions do
    # `citext` backs Ash's `:ci_string` and ships with stock PostgreSQL.
    #
    # No `vector`, no `postgis`. Enabling an extension is one line in a migration
    # whenever it happens; the real cost is that every environment's Postgres has
    # to ship the binaries, and that cost is the same whenever it is paid. Each
    # arrives in the slice that first needs it, with a test that exercises it.
    ["ash-functions", "citext"]
  end

  # Don't open unnecessary transactions
  # will default to `false` in 4.0
  @impl true
  def prefer_transaction? do
    false
  end

  @impl true
  def min_pg_version do
    %Version{major: 18, minor: 4, patch: 0}
  end
end
