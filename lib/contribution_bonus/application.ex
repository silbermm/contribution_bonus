defmodule ContributionBonus.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias ContributionBonus.OrganizationSupervisor

  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Registry.Organization},
      {Registry, keys: :unique, name: Registry.Contribution},
      OrganizationSupervisor
    ]

    opts = [strategy: :one_for_one, name: ContributionBonus.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
