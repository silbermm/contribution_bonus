defmodule ContributionBonus.ContributionSupervisor do
  use Supervisor

  alias ContributionBonus.Contribution

  def start_link(_opts), do: Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(:ok), do: Supervisor.init([Contribution], strategy: :simple_one_for_one)

  def start_contribution(campaign, campaign_member) do
    Supervisor.start_child(__MODULE__, [{campaign, campaign_member}])
  end

end
