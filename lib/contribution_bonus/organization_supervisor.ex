defmodule ContributionBonus.OrganizationSupervisor do
  use Supervisor

  alias ContributionBonus.Organization

  def start_link(_opts), do: Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(:ok), do: Supervisor.init([Organization], strategy: :simple_one_for_one)

  def create_organization(name) do
    Supervisor.start_child(__MODULE__, [name])
  end

  def remove_organization(name) do
    Supervisor.terminate_child(__MODULE__, find_organization(name))
  end

  def find_organization(name) do
    name
    |> Organization.via_tuple()
    |> GenServer.whereis()
  end
end
