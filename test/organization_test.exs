defmodule ContributionBonus.OrganizationTest do
  use ExUnit.Case, async: true
  import ContributionBonus.Factory

  alias ContributionBonus.{Organization, Member}

  test "creates a new organization" do
    assert {:ok, %Organization{name: "testings", members: []}} == Organization.new("testings")
  end

  test "adds a member to an organization" do
    {:ok, org} = Organization.new("testings")
    member = build(:member)
    org = Organization.add_member(org, member)

    assert org.members == [member]
  end

  test "unable to add member if org doesn't have a name" do
    assert :error == Organization.add_member(%Organization{}, %{})
  end
end
