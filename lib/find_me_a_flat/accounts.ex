defmodule FindMeAFlat.Accounts do
  @moduledoc """
  Who the system knows: the `Operator` who runs the deployment, and (from S5) the
  `Subscriber`s who receive listings.

  The two are deliberately different resources. One deployment serves everybody, so
  policies are the only separation there is, and an `Operator` must never satisfy a
  `Subscriber` policy by accident of sharing a table.
  """

  use Ash.Domain,
    otp_app: :find_me_a_flat

  resources do
    resource FindMeAFlat.Accounts.Operator
  end
end
