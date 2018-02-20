defmodule ContributionBonus.CampaignTest do
  use ExUnit.Case

  alias ContributionBonus.{Campaign}
  import ContributionBonus.Factory

  setup do
    [campaign_members: build_list(4, :campaign_member)]
  end

  test "creates a new campaign" do
    {:ok, campaign} = Campaign.new("test", Date.utc_today(), Date.add(Date.utc_today(), 8))
    assert campaign.title == "test"
    assert campaign.start_date == Date.utc_today()
  end

  test "adds new members", %{campaign_members: members} do
    {:ok, campaign} = Campaign.new("test", Date.utc_today(), Date.add(Date.utc_today(), 8))
    {:ok, campaign} = Campaign.add_members(campaign, members)
    assert Enum.count(campaign.campaign_members) == 4
  end
end
