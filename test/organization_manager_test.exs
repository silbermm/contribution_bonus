defmodule ContributionBonus.OrganziationManagerTest do
  use ExUnit.Case

  import ContributionBonus.Factory
  alias ContributionBonus.{OrganizationManager}

  describe "adds organization members" do
    setup :ingage_org

    test "add member to organization", %{pid: pid} do
      {:ok, member} =
        OrganizationManager.add_member(pid, "Matt", "Silbernagel", "silbermm@gmail.com")

      assert member.first_name == "Matt"
      assert member.last_name == "Silbernagel"
    end

    test "fails to add member with same email", %{pid: pid} do
      {:ok, member} =
        OrganizationManager.add_member(pid, "Matt", "Silbernagel", "silbermm@gmail.com")

      assert member.first_name == "Matt"
      assert member.last_name == "Silbernagel"

      assert {:error, "Email is already used in the organization"} ==
               OrganizationManager.add_member(pid, "Leslie", "Silbernagel", "silbermm@gmail.com")
    end

    test "fails to add member - bad email", %{pid: pid} do
      {:error, msg} = OrganizationManager.add_member(pid, "Matt", "silbernagel", "")
      assert msg == "unable to create a new member"
    end
  end

  describe "creates campaign" do
    setup [:ingage_org, :with_members]

    test "creates a campaign", %{pid: pid} do
      {:ok, campaign} =
        OrganizationManager.create_campaign(
          pid,
          "Contribution Bonus 2018",
          ~D[2018-11-01],
          ~D[2018-12-21]
        )

      assert campaign.title == "Contribution Bonus 2018"
      state = :sys.get_state(pid)
      assert List.first(state.campaigns).title == "Contribution Bonus 2018"
    end

    test "requires proper dates", %{pid: pid} do
      {:error, reason} =
        OrganizationManager.create_campaign(pid, "Contrib Bonus 2018", nil, ~D[2018-12-21])

      assert reason == "invalid date(s)"
    end

    test "unable to add a campaign member before creating campaign", %{pid: pid, members: members} do
      campaign = build(:campaign)
      member = List.first(members)

      {:error, msg} =
        OrganizationManager.add_member_to_campaign(pid, member, campaign, "1000", true)

      assert msg == "campaign does not exist"
    end
  end

  describe "adds campaign members" do
    setup [:ingage_org, :with_members, :with_campaign]

    test "one campaign member", %{pid: pid, members: members, campaign: campaign} do
      member = List.first(members)
      {:ok, result} = OrganizationManager.add_member_to_campaign(pid, member, campaign, 1000)
      assert result.can_receive? == true
      state = :sys.get_state(pid)
      cp = List.first(state.campaigns)
      assert Enum.count(cp.campaign_members) == 1
    end

    test "many campaign members", %{pid: pid, members: members, campaign: campaign} do
      {:ok, _campaign, {added, _erred}} =
        OrganizationManager.add_members_to_campaign(pid, members, campaign, 1000)

      assert Enum.count(members) == Enum.count(added)
      state = :sys.get_state(pid)
      cp = List.first(state.campaigns)
      assert Enum.count(cp.campaign_members) == Enum.count(members)
    end

    test "do not add member to campaign if not a member of the org", %{
      pid: pid,
      members: members,
      campaign: campaign
    } do
      members = members ++ [build(:member)]
      {:ok, _campaign, {added, erred}} =
        OrganizationManager.add_members_to_campaign(pid, members, campaign, 1000)
      assert 1 == Enum.count(erred)
    end
  end

  defp ingage_org(context) do
    {:ok, pid} = OrganizationManager.start_link("Ingage Partners")
    [pid: pid]
  end

  defp with_members(context) do
    members = build_list(4, :member)

    Enum.each(
      members,
      &OrganizationManager.add_member(context.pid, &1.first_name, &1.last_name, &1.email)
    )

    Map.put(context, :members, members)
  end

  defp with_campaign(context) do
    campaign = build(:campaign)

    {:ok, campaign} =
      OrganizationManager.create_campaign(
        context.pid,
        campaign.title,
        campaign.start_date,
        campaign.end_date
      )

    Map.put(context, :campaign, campaign)
  end
end
