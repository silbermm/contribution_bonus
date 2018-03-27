defmodule ContributionBonus.Factory do
  use ExMachina
  alias ContributionBonus.{Organization, Member, Campaign, CampaignMember}

  def organization_factory do
    %Organization{
      name: sequence("org_name")
    }
  end

  def member_factory do
    %Member{
      first_name: sequence("first_name"),
      last_name: sequence("last_name"),
      email: sequence("email", &"me-#{&1}@foo.com")
    }
  end

  def campaign_member_factory do
    %CampaignMember{
      member: build(:member),
      amount_to_give: 1000,
      can_receive?: true
    }
  end

  def campaign_factory do
    %Campaign{
      id: sequence("random_id"),
      title: sequence("title"),
      start_date: Date.utc_today(),
      end_date: Date.add(Date.utc_today(), 20)
    }
  end
end
