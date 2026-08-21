defmodule FindMeAFlat.Accounts.Operator do
  @moduledoc """
  The person who runs this deployment: the recipient of portal-health alerts and,
  from S16, the only login on the admin surface.

  An operator is not a subscriber. There is one of them, they have no searches, and
  no policy written for subscribers may ever admit them.
  """

  use Ash.Resource,
    otp_app: :find_me_a_flat,
    domain: FindMeAFlat.Accounts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "operators"
    repo FindMeAFlat.Repo
  end

  actions do
    defaults [:read, create: [:email], update: [:email]]
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :email, :ci_string do
      allow_nil? false
      public? true
    end

    timestamps()
  end
end
