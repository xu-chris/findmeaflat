defmodule FindMeAFlat.Listings do
  @moduledoc """
  Everything a portal published, and every `Delivery` made from it. Empty in S1;
  S7 fills it.

  Listings are stored permanently, description and images included: the accumulated
  dataset is the product, and those fields are unrecoverable once a flat is delisted.
  """

  use Ash.Domain,
    otp_app: :find_me_a_flat

  resources do
  end
end
