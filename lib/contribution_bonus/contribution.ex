defmodule ContributionBonus.Contribution do
  use GenServer, start: {__MODULE__, :start_link, []}, restart: :transient

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
    {:ok, %{campaign: campaign, campaign_member: campaign_member, contributions: MapSet.new()}}
  end

  def contribute_to(pid, campaign_member, amount, txt),
    do: GenServer.call(pid, {:contribute_to, campaign_member, amount, txt})

  def current_balance(pid), do: GenServer.call(pid, :current_balance)

  def handle_call({:contribute_to, campaign_member, amount, txt}, _from, state) do
    with :valid <- contributee_status(state, campaign_member),
         :ok <- verify_dates(state),
         {:ok, left_to_give} <- verify_money(state, amount),
         true <- campaign_member.can_receive?,
         contribution <- %Contribution{
           campaign_member: campaign_member,
           amount: amount,
           txt: txt
         } do
      state
      |> update_contributions(contribution)
      |> reply_success({:ok, left_to_give - amount})
    else
      {:invalid, contribution} -> edit_contribution(state, contribution, amount, txt)
      {:error, err_msg} -> reply_error(state, err_msg)
      false -> reply_error(state, "member is not eligible to receive funds")
    end
  end

  def handle_call(:current_balance, _from, state) do
    reply_success(state, amount_left(state))
  end

  defp reply_success(state, reply), do: {:reply, reply, state}

  defp reply_error(state, msg), do: {:reply, {:error, msg}, state}

  defp edit_contribution(state, old_contribution, amount, txt) do
    state = update_contributions(state, old_contribution, :delete)

    with {:ok, left_to_give} <- verify_money(state, amount) do
      new_contribution = %__MODULE__{old_contribution | amount: amount}

      state
      |> update_contributions(new_contribution, :add)
      |> reply_success({:ok, left_to_give - amount})
    else
      {:error, err_msg} ->
        state
        |> update_contributions(old_contribution, :add)
        |> reply_error(err_msg)
    end
  end

  defp update_contributions(state, contribution, operation \\ :add) do
    case operation do
      :add ->
        Map.put(state, :contributions, add_contribution(state.contributions, contribution))

      :delete ->
        Map.put(state, :contributions, remove_contribution(state.contributions, contribution))

      _ ->
        state
    end
  end

  defp add_contribution(current_contributions, contribution) do
    current_contributions
    |> MapSet.put(contribution)
  end

  defp remove_contribution(current_contributions, contribution) do
    current_contributions
    |> MapSet.delete(contribution)
  end

  defp contributee_status(state, campaign_member) do
    state.contributions
    |> Enum.find(fn contribution ->
      CampaignMember.is_same?(contribution.campaign_member, campaign_member)
    end)
    |> case do
      nil -> :valid
      contribution -> {:invalid, contribution}
    end
  end

  defp verify_dates(%{campaign: campaign} = state) do
    case verify_start_date(campaign.start_date) do
      :ok -> verify_end_date(campaign.end_date)
      err -> err
    end
  end

  defp verify_end_date(end_date) do
    case Date.compare(Date.utc_today(), end_date) do
      :gt -> {:error, "campaign has ended"}
      _ -> :ok
    end
  end

  defp verify_start_date(start_date) do
    case Date.compare(Date.utc_today(), start_date) do
      :gt -> :ok
      :eq -> :ok
      _ -> {:error, "campaign has not started"}
    end
  end

  defp verify_money(state, amount_to_give) when amount_to_give > 0 do
    left_to_give = amount_left(state)

    if left_to_give - amount_to_give >= 0 do
      {:ok, left_to_give}
    else
      {:error, "insufficient funds"}
    end
  end

  defp verify_money(_state, _amount), do: {:error, "must give more than $0"}

  defp amount_left(state) do
    given_so_far = amount_given(state)
    state.campaign_member.amount_to_give - given_so_far
  end

  defp amount_given(state) do
    state.contributions
    |> Enum.map(& &1.amount)
    |> Enum.sum()
  end

  def via_tuple(campaign, campaign_member) do
    identifier = campaign.id <> campaign_member.member.email
    {:via, Registry, {Registry.Contribution, identifier}}
  end
end
