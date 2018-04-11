defmodule ContributionBonus.ContributionManagerTest do
  use ExUnit.Case

  import ContributionBonus.Factory
  alias ContributionBonus.{ContributionManager}

  setup do
    campaign = build(:campaign)
    me = build(:campaign_member)
    eligible = build(:campaign_member)
    ineligible = build(:campaign_member) |> Map.put(:can_receive?, false)
    {:ok, pid} = ContributionManager.start_link({campaign, me})
    [eligible: eligible, ineligible: ineligible, pid: pid]
  end

  test "contributes successfully", %{pid: pid, eligible: eligible} do
    assert {:ok, 0} == ContributionManager.contribute_to(pid, eligible, 1000, "here ya go!")
  end

  test "not enough funds", %{pid: pid, eligible: eligible} do
    assert {:error, "insufficient funds"} ==
             ContributionManager.contribute_to(pid, eligible, 1001, "here ya go!")
  end

  test "give all to first person, not enough for second", %{pid: pid, eligible: eligible} do
    second = build(:campaign_member)
    ContributionManager.contribute_to(pid, second, 1000, "you're the best")

    assert {:error, "insufficient funds"} ==
             ContributionManager.contribute_to(pid, eligible, 1001, "here ya go!")
  end

  test "ineligible recipient", %{pid: pid, ineligible: ineligible} do
    assert {:error, "member is not eligible to receive funds"} ==
             ContributionManager.contribute_to(pid, ineligible, 1, "here ya go!")
  end

  test "change contribution amount", %{pid: pid, eligible: eligible} do
    assert {:ok, 500} == ContributionManager.contribute_to(pid, eligible, 500, "here ya go!")
    assert {:ok, 0} == ContributionManager.contribute_to(pid, eligible, 1000, "here ya go!")
  end

  test "fails change contribution amount, should keep current state", %{
    pid: pid,
    eligible: eligible
  } do
    assert Enum.count(:sys.get_state(pid).contributions) == 0
    assert {:ok, 500} == ContributionManager.contribute_to(pid, eligible, 500, "here ya go!")

    assert Enum.count(:sys.get_state(pid).contributions) == 1

    assert {:error, "insufficient funds"} ==
             ContributionManager.contribute_to(pid, eligible, 1500, "here ya go!")

    assert Enum.count(:sys.get_state(pid).contributions) == 1
  end

  test "query amount left to give", %{pid: pid, eligible: eligible} do
    ContributionManager.contribute_to(pid, eligible, 500, "here ya go!")
    assert 500 == ContributionManager.current_balance(pid)
  end
end
