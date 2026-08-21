defmodule FindMeAFlat.Searches do
  @moduledoc """
  What each subscriber is looking for: a `Search` and the `Watch`es that check one
  portal for it. Empty in S1; S6 fills it.
  """

  use Ash.Domain,
    otp_app: :find_me_a_flat

  resources do
  end
end
