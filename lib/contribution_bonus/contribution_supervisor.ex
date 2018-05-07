defmodule ContributionBonus.ContributionSupervisor do
  use DynamicSupervisor

  alias ContributionBonus.Contribution

  def start_link(_opts), do: DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(:ok), do: DynamicSupervisor.init(strategy: :one_for_one)

  def start_child(campaign, campaign_member) do
    spec = {Contribution, campaign: campaign, campaign_member: campaign_member}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def start_contribution(campaign, campaign_member) do
    start_child(campaign, campaign_member)
  end
end
