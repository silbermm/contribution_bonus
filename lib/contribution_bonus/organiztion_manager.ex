defmodule ContributionBonus.OrganizationManager do
  use GenServer
  alias ContributionBonus.{Organization, Member, Campaign, CampaignMember}

  def start_link(org_name),
    do: GenServer.start_link(__MODULE__, org_name, name: via_tuple(org_name))

  def init(org_name) do
    {:ok, org} = Organization.new(org_name)
    {:ok, %{organization: org, campaigns: []}}
  end

  # CLIENT FUNCTIONS
  def add_member(org, first_name, last_name, email),
    do: GenServer.call(org, {:add_member, first_name, last_name, email})

  def create_campaign(org, title, start_date, end_date),
    do: GenServer.call(org, {:create_campaign, title, start_date, end_date})

  def add_member_to_campaign(org, member, campaign, amount, can_receive \\ true),
    do: GenServer.call(org, {:add_campaign_member, member, campaign, amount, can_receive})

  # SERVER METHODS
  def handle_call({:add_member, first_name, last_name, email}, _from, state) do
    with {:ok, member} <- Member.new(first_name, last_name, email),
         %Organization{} = org <- Organization.add_member(state.organization, member) do
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
      _ -> reply_error(state, "unable to create a new campaign")
    end
  end

  def handle_call({:add_campaign_member, member, campaign, amount, can_receive}, _from, state) do
    with :valid_member <- valid_member(state, member),
         :valid_campaign <- valid_campaign(state, campaign),
         %CampaignMember{} = cm <- CampaignMember.new(member, can_receive, amount) do
      state
      |> IO.inspect(label: "add method to add campaign member to state")
      |> reply_success({:ok, cm})
    else
      :invalid_member -> reply_error(state, "member does not exist")
      :invalid_campaign -> reply_error(state, "campaign does not exist")
      {:error, msg} -> reply_error(state, msg)
    end
  end

  def via_tuple(org_name), do: {:via, Registry, {Registry.Organization, org_name}}

  defp reply_success(state, reply), do: {:reply, reply, state}

  defp reply_error(state, msg), do: {:reply, {:error, msg}, state}

  defp update_org(state, new_org), do: %{state | organization: new_org}

  defp add_campaign(%{campaigns: campaigns} = state, campaign),
    do: put_in(state, [:campaigns], campaigns ++ [campaign])

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
end
