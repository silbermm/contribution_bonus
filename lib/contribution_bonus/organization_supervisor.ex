defmodule ContributionBonus.OrganizationSupervisor do
  use DynamicSupervisor

  alias ContributionBonus.Organization

  def start_link(_opts), do: DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(:ok), do: DynamicSupervisor.init(strategy: :one_for_one)

  def start_child(name) do
    DynamicSupervisor.start_child(__MODULE__, {Organization, name: name})
  end

  def create_organization(name) do
    start_child(name)
  end

  def remove_organization(name) do
    DynamicSupervisor.terminate_child(__MODULE__, find_organization(name))
  end

  def find_organization(name) do
    name
    |> Organization.via_tuple()
    |> GenServer.whereis()
  end
end
