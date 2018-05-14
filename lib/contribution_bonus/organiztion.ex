defmodule ContributionBonus.Organization do
  use GenServer, restart: :transient
  alias ContributionBonus.{Member, Campaign, CampaignMember, StateRepo}
  alias __MODULE__

  @timeout 20_000

  defstruct name: nil, members: []

  def start_link(name: org_name),
    do: GenServer.start_link(__MODULE__, org_name, name: via_tuple(org_name))

  def init(org_name) do
    state = case StateRepo.find(__MODULE__, org_name) do
      [] = %{organization: %Organization{name: org_name}, campaigns: []}
      [{_key, value}] -> value
    end
    :ok = StateRepo.update(__MODULE__, {org_name, state})
    {:ok, state, @timeout}
  end

  # CLIENT FUNCTIONS
  def add_member(org, first_name, last_name, email),
    do: GenServer.call(org, {:add_member, first_name, last_name, email})

  def create_campaign(org, title, start_date, end_date),
    do: GenServer.call(org, {:create_campaign, title, start_date, end_date})

  def add_member_to_campaign(org, member, campaign, amount, can_receive \\ true),
    do: GenServer.call(org, {:add_campaign_member, member, campaign, amount, can_receive})

  def add_members_to_campaign(org, members, campaign, amount, can_receive \\ true)
      when is_list(members),
      do: GenServer.call(org, {:add_campaign_members, members, campaign, amount, can_receive})

  def get_members(org), do: GenServer.call(org, {:get_members})

  def get_campaign_members(org, campaign),
    do: GenServer.call(org, {:get_campaign_members, campaign})

  # SERVER METHODS
  def handle_call({:add_member, first_name, last_name, email}, _from, state) do
    with {:ok, member} <- Member.new(first_name, last_name, email),
         %Organization{} = org <- add_member_to_org(state.organization, member) do
      state
      |> update_org(org)
      |> reply_success({:ok, member})
    else
      {:error, "already exists"} ->
        reply_error(state, "Email is already used in the organization")

      {:error, _msg} ->
        reply_error(state, "unable to create a new member")

      :error ->
        reply_error(state, "unable to add member")
    end
  end

  def handle_call({:create_campaign, title, start, end_date}, _from, state) do
    with {:ok, campaign} <- Campaign.new(title, start, end_date) do
      state
      |> add_campaign(campaign)
      |> reply_success({:ok, campaign})
    else
      {:error, msg} -> reply_error(state, msg)
    end
  end

  def handle_call({:add_campaign_member, member, campaign, amount, can_receive}, _from, state) do
    with :valid_member <- valid_member(state, member),
         :valid_campaign <- valid_campaign(state, campaign),
         {:ok, %CampaignMember{} = cm} <- CampaignMember.new(member, can_receive, amount),
         {:ok, new_campaign} <- Campaign.add_member(campaign, cm) do
      state
      |> replace_campaign(new_campaign)
      |> reply_success({:ok, cm})
    else
      :invalid_member -> reply_error(state, "member does not exist")
      :invalid_campaign -> reply_error(state, "campaign does not exist")
      {:error, msg} -> reply_error(state, msg)
    end
  end

  def handle_call({:add_campaign_members, members, campaign, amount, can_receive}, _from, state) do
    with :valid_campaign <- valid_campaign(state, campaign),
         {valid_members, invalid_members} <-
           split_campaign_members(state, members, amount, can_receive),
         valid <- Enum.map(valid_members, fn {:ok, cm} -> cm end),
         invalid <- Enum.map(invalid_members, fn {:error, cm} -> cm end),
         {:ok, campaign} <- Campaign.add_members(campaign, valid) do
      state
      |> replace_campaign(campaign)
      |> reply_success({:ok, campaign, {valid, invalid}})
    else
      :invalid_campaign -> reply_error(state, "campaign does not exist")
      {:error, err} -> reply_error(state, err)
    end
  end

  def handle_call({:get_members}, _from, state) do
    {:reply, state.organization.members, state, @timeout}
  end

  def handle_call({:get_campaign_members, campaign}, _from, state) do
    members =
      state.campaigns
      |> Enum.find(fn c -> c.id == campaign.id end)
      |> _get_campaign_members

    {:reply, members, state, @timeout}
  end

  def handle_info(:timeout, state), do: {:stop, {:shutdown, :timeout}, state}

  def via_tuple(org_name), do: {:via, Registry, {Registry.Organization, org_name}}

  defp reply_success(state, reply), do: {:reply, reply, state, @timeout}

  defp reply_error(state, msg), do: {:reply, {:error, msg}, state, @timeout}

  defp update_org(state, new_org), do: %{state | organization: new_org}

  defp add_campaign(%{campaigns: campaigns} = state, campaign),
    do: put_in(state, [:campaigns], campaigns ++ [campaign])

  defp create_campaign_member(state, member, can_receive, amount) do
    with :valid_member <- valid_member(state, member),
         {:ok, %CampaignMember{} = cm} <- CampaignMember.new(member, can_receive, amount) do
      {:ok, cm}
    else
      :invalid_member -> {:error, member}
      _ -> {:error, member}
    end
  end

  defp split_campaign_members(state, members, amount, can_receive) do
    members
    |> Enum.map(&create_campaign_member(state, &1, can_receive, amount))
    |> Enum.split_with(fn {ok_or_err, _} -> ok_or_err == :ok end)
  end

  defp replace_campaign(%{campaigns: campaigns} = state, campaign) do
    idx = Enum.find_index(campaigns, &(&1.id == campaign.id))
    campaigns = List.replace_at(campaigns, idx, campaign)
    put_in(state, [:campaigns], campaigns)
  end

  defp valid_member(state, %Member{email: email} = _member) do
    state.organization.members
    |> Enum.any?(&(&1.email == email))
    |> case do
      true -> :valid_member
      _ -> :invalid_member
    end
  end

  defp valid_campaign(state, %Campaign{id: id} = _campaign) do
    state.campaigns
    |> Enum.any?(&(&1.id == id))
    |> case do
      true -> :valid_campaign
      _ -> :invalid_campaign
    end
  end

  defp _get_campaign_members(nil), do: []
  defp _get_campaign_members(campaign), do: campaign.campaign_members

  defp add_member_to_org(%Organization{name: name, members: members} = org, %Member{} = member)
       when not is_nil(name) do
    to_add = Enum.any?(org.members, &(&1.email == member.email))
    _add_member(org, member, members, to_add)
  end

  defp add_member_to_org(_org, _member), do: :error

  defp _add_member(org, member, current, false),
    do: %{org | members: Enum.concat(current, [member])}

  defp _add_member(_organization, _member, _current, true), do: {:error, "already exists"}
end
