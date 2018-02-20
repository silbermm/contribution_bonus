defmodule ContributionBonus.CampaignMemberTest do
  use ExUnit.Case

  import ContributionBonus.Factory
  alias ContributionBonus.CampaignMember

  setup do
    [member: build(:member)]
  end

  test "creates new campaign member", %{member: member} do
    {:ok, campaign_member} = CampaignMember.new(member, true)
    assert campaign_member.member == member
  end

  test "changes the amount to give", %{member: member} do
    {:ok, campaign_member} = CampaignMember.new(member, true, 500)
    assert campaign_member.amount_to_give == 500
  end

  test "must be have a valid member" do
    assert {:error, "invalid campaign member"} == CampaignMember.new(%{}, true)
  end
end
