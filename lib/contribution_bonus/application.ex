defmodule ContributionBonus.Application do
  @moduledoc false

  use Application

  alias ContributionBonus.{
    OrganizationSupervisor,
    ContributionSupervisor,
    Contribution,
    Organization,
    StateRepo
  }

  def start(_type, _args) do
    StateRepo.create_tables([Contribution, Organization])

    children = [
      {Registry, keys: :unique, name: Registry.Organization},
      {Registry, keys: :unique, name: Registry.Contribution},
      OrganizationSupervisor,
      ContributionSupervisor
    ]

    opts = [strategy: :one_for_one, name: ContributionBonus.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
