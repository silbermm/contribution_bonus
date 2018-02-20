defmodule ContributionBonus.Campaign do
  alias __MODULE__
  alias ContributionBonus.{CampaignMember}

  defstruct [:title, :start_date, :end_date, :campaign_members]

  def new(title, start_date, end_date),
    do:
      {:ok,
       %Campaign{title: title, start_date: start_date, end_date: end_date, campaign_members: []}}

  def add_member(campaign, %CampaignMember{} = member),
    do: {:ok, %{campaign | campaign_members: campaign.campaign_members ++ [member]}}

  def add_member(_campaign, _), do: {:error, "unable to add campaign member"}

  def add_members(campaign, [_ | _] = members),
    do: {:ok, %{campaign | campaign_members: campaign.campaign_members ++ members}}

  def add_members(campaign, _members), do: {:error, "unable to add campaign members"}
end
