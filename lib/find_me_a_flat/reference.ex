defmodule FindMeAFlat.Reference do
  @moduledoc """
  Reserved for the open reference data of Phase 2 — Mietspiegel rents, buildings,
  providers.

  Deliberately empty in Phase 1. It exists now so that enrichment lands in its own
  domain rather than growing sideways out of `Listings`.
  """

  use Ash.Domain,
    otp_app: :find_me_a_flat

  resources do
  end
end
