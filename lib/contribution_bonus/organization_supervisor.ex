defmodule ContributionBonus.OrganizationSupervisor do
  use Supervisor

  alias ContributionBonus.OrganizationManager

  def start_link(),
    do: Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(:ok),
    do: Supervisor.init([OrganizationManager], strategy: :simple_one_for_one)

  def create_org(name) do
    Supervisor.start_child(__MODULE__, [name])
  end

end
