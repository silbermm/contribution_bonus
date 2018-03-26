defmodule ContributionBonus.CampaignMember do
  alias __MODULE__
  alias ContributionBonus.Member

  defstruct [:member, :can_receive?, :amount_to_give]

  def new(member, can_receive? \\ true, amount_to_give \\ 1000)

  def new(%Member{} = member, can_receive?, amount_to_give) when is_boolean(can_receive?) do
    {:ok,
     %CampaignMember{member: member, can_receive?: can_receive?, amount_to_give: amount_to_give}}
  end

  def new(_member, _can_receive, _amount), do: {:error, "invalid campaign member"}

  def is_same?(%CampaignMember{member: member1}, %CampaignMember{member: member2}) do
    member1.email == member2.email
  end
end
