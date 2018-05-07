defmodule ContributionBonus.OrganziationTest do
  use ExUnit.Case, async: false

  import ContributionBonus.Factory
  alias ContributionBonus.{OrganizationSupervisor, Organization}

  setup do
    on_exit(&remove_org/0)
    :ok
  end

  describe "adds organization members" do
    setup :ingage_org

    test "add member to organization", %{pid: pid} do
      {:ok, member} = Organization.add_member(pid, "Matt", "Silbernagel", "silbermm@gmail.com")

      assert member.first_name == "Matt"
      assert member.last_name == "Silbernagel"
    end

    test "fails to add member with same email", %{pid: pid} do
      {:ok, member} = Organization.add_member(pid, "Matt", "Silbernagel", "silbermm@gmail.com")

      assert member.first_name == "Matt"
      assert member.last_name == "Silbernagel"

      assert {:error, "Email is already used in the organization"} ==
               Organization.add_member(pid, "Leslie", "Silbernagel", "silbermm@gmail.com")
    end

    test "fails to add member - bad email", %{pid: pid} do
      {:error, msg} = Organization.add_member(pid, "Matt", "silbernagel", "")
      assert msg == "unable to create a new member"
    end
  end

  describe "creates campaign" do
    setup [:ingage_org, :with_members]

    test "creates a campaign", %{pid: pid} do
      {:ok, campaign} =
        Organization.create_campaign(
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
        Organization.create_campaign(pid, "Contrib Bonus 2018", nil, ~D[2018-12-21])

      assert reason == "invalid date(s)"
    end

    test "unable to add a campaign member before creating campaign", %{pid: pid, members: members} do
      campaign = build(:campaign)
      member = List.first(members)

      {:error, msg} = Organization.add_member_to_campaign(pid, member, campaign, "1000", true)

      assert msg == "campaign does not exist"
    end

    test "unable to create an org if already exists", %{pid: pid} do
      {:error, reason} = Organization.start_link(name: "Ingage Partners")
      assert reason == {:already_started, pid}
    end
  end

  describe "adds campaign members" do
    setup [:ingage_org, :with_members, :with_campaign]

    test "one campaign member", %{pid: pid, members: members, campaign: campaign} do
      member = List.first(members)
      {:ok, result} = Organization.add_member_to_campaign(pid, member, campaign, 1000)
      assert result.can_receive? == true
      state = :sys.get_state(pid)
      cp = List.first(state.campaigns)
      assert Enum.count(cp.campaign_members) == 1
    end

    test "many campaign members", %{pid: pid, members: members, campaign: campaign} do
      {:ok, _campaign, {added, _erred}} =
        Organization.add_members_to_campaign(pid, members, campaign, 1000)

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

      {:ok, _campaign, {_added, erred}} =
        Organization.add_members_to_campaign(pid, members, campaign, 1000)

      assert 1 == Enum.count(erred)
    end
  end

  describe "gets data" do
    setup [:ingage_org, :with_members, :with_campaign, :with_campaign_members]

    test "gets campaign members", %{
      pid: pid,
      campaign: campaign,
      campaign_members: campaign_members
    } do
      assert campaign_members == Organization.get_campaign_members(pid, campaign)
    end

    test "gets organization members", %{pid: pid, members: members} do
      assert members == Organization.get_members(pid)
    end
  end

  defp ingage_org(_context) do
    {:ok, pid} = OrganizationSupervisor.create_organization("Ingage Partners")
    [pid: pid]
  end

  defp with_members(context) do
    members = build_list(4, :member)

    Enum.each(
      members,
      &Organization.add_member(context.pid, &1.first_name, &1.last_name, &1.email)
    )

    Map.put(context, :members, members)
  end

  defp with_campaign(context) do
    campaign = build(:campaign)

    {:ok, campaign} =
      Organization.create_campaign(
        context.pid,
        campaign.title,
        campaign.start_date,
        campaign.end_date
      )

    Map.put(context, :campaign, campaign)
  end

  defp with_campaign_members(context) do
    {:ok, _campaign, {added, _err}} =
      Organization.add_members_to_campaign(
        context.pid,
        context.members,
        context.campaign,
        1000
      )

    Map.put(context, :campaign_members, added)
  end

  defp remove_org do
    OrganizationSupervisor.remove_organization("Ingage Partners")
  end
end
