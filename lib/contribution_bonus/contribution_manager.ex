defmodule ContributionBonus.ContributionManager do
  use GenServer

  alias __MODULE__
  alias ContributionBonus.CampaignMember

  defstruct [:campaign_member, :amount, :txt]

  def start_link({campaign, campaign_member}) do
    GenServer.start_link(
      __MODULE__,
      {campaign, campaign_member},
      name: via_tuple(campaign, campaign_member)
    )
  end

  def init({campaign, campaign_member}) do
    {:ok, %{campaign: campaign, campign_member: campaign_member, contributions: MapSet.new()}}
  end

  def contribute_to(pid, campaign_member, amount, txt),
    do: GenServer.call(pid, {:contribute_to, campaign_member, amount, txt})

  def handle_call({:contribute_to, campaign_member, amount, txt}, _from, state) do
    with {:ok, left_to_give} <- verify_money(state, amount),
         true <- campaign_member.can_receive?,
         :valid <- contributee_status(state, campaign_member),
         contribution <- %ContributionManager{
           campaign_member: campaign_member,
           amount: amount,
           txt: txt
         } do
      state
      |> update_contributions(contribution)
      |> reply_success({:ok})
    else
      {:error, err_msg} -> reply_error(state, err_msg)
      false -> reply_error(state, "member is not eligible to receive funds")
      :invalid -> reply_error(state, "already contributed to member")
    end
  end

  defp reply_success(state, reply), do: {:reply, reply, state}

  defp reply_error(state, msg), do: {:reply, {:error, msg}, state}

  defp update_contributions(state, contribution) do
    state
    |> Map.put(:contributions, add_contribution(state.contributions, contribution))
  end

  defp add_contribution(current_contributions, contribution) do
    current_contributions
    |> MapSet.put(contribution)
  end

  defp contributee_status(state, campaign_member) do
    state.contributions
    |> Enum.find(fn contribution ->
      CampaignMember.is_same?(contribution.campaign_member, campaign_member)
    end)
    |> case do
      nil -> :valid
      _ -> :invalid
    end
  end

  defp verify_money(state, amount_to_give) when amount_to_give > 0 do
    given_so_far = amount_given(state)
    left_to_give = state.campaign_member.amount_to_give - given_so_far

    case left_to_give > 0 do
      true -> {:ok, left_to_give}
      false -> {:error, "no money left to give"}
    end
  end

  defp verify_money(_state, _amount), do: {:error, "must give more than $0"}

  defp amount_given(state) do
    state.contributions
    |> Enum.map(& &1.amount)
    |> Enum.sum()
  end

  def via_tuple(campaign, campaign_member) do
    identifier = campaign.campaign_id <> campaign_member.member.email
    {:via, Registry, {Registry.Contribution, identifier}}
  end
end
