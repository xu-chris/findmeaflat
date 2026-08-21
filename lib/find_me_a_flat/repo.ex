defmodule FindMeAFlat.Repo do
  use AshPostgres.Repo,
    otp_app: :find_me_a_flat

  @impl true
  def installed_extensions do
    # `citext` backs Ash's `:ci_string`. `vector` is enabled now because adding an
    # extension to a live database later is a migration nobody enjoys; Phase 1 uses
    # neither it nor `postgis`, and no stock PostgreSQL 18 image carries both, so
    # `postgis` waits for the slice that first needs it (PLAN.md, S1).
    ["ash-functions", "citext", "vector"]
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
