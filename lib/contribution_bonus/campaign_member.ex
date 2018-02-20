defmodule ContributionBonus.CampaignMember do
  alias __MODULE__
  alias ContributionBonus.Member

  defstruct [:member, :can_receive?, :amount_to_give]

  def new(%Member{} = member, can_receive?, amount_to_give \\ 1000) when is_boolean(can_receive?) do
    {:ok,
     %CampaignMember{member: member, can_receive?: can_receive?, amount_to_give: amount_to_give}}
  end

  def new(_member, _can_receive, _ammount), do: {:error, "invalid campaign member"}
end
