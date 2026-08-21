defmodule FindMeAFlat.Portals do
  @moduledoc """
  The portals themselves and their health. Empty in S1; S2 onwards fill it.

  A persistence domain: it owns rows, never processes. The adapters that parse each
  portal are behaviour implementations under `FindMeAFlat.Portals.Adapter`, and the
  processes that pace requests live in `FindMeAFlat.Fetching`.
  """

  use Ash.Domain,
    otp_app: :find_me_a_flat

  resources do
  end
end
