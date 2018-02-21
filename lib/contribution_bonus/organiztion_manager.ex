defmodule ContributionBonus.OrganizationManager do
  use GenServer
  alias ContributionBonus.{Organization, Member}

  def start_link(org_name),
    do: GenServer.start_link(__MODULE__, org_name, name: via_tuple(org_name))

  def init(org_name) do
    {:ok, org} = Organization.new(org_name)
    {:ok, %{organization: org}}
  end

  def add_member(org, first_name, last_name, email),
    do: GenServer.call(org, {:add_member, first_name, last_name, email})

  def create_campaign(org, title, start_date, end_date),
    do: GenServer.call(org, {:create_campaign, title, start_date, end_date})

  def via_tuple(org_name), do: {:via, Registry, {Registry.Organization, org_name}}

  def handle_call({:add_member, first_name, last_name, email}, _from, state) do
    with {:ok, member} <- Member.new(first_name, last_name, email),
         %Organization{} = org <- Organization.add_member(state.organization, member) do
      state
      |> update_org(org)
      |> reply_success({:ok, org})
    else
      {:error, "already exists"} ->
        {:reply, {:error, "Email is already used in the organization"}, state}

      {:error, _msg} ->
        {:reply, {:error, "unable to create a new member"}, state}

      :error ->
        {:reply, {:error, "unable to add member"}, state}
    end
  end

  def handle_call({:create_campaign, title, start, end_date}, _from, state) do
    reply_success(state, :ok)
  end

  defp reply_success(state, reply) do
    {:reply, reply, state}
  end

  defp update_org(state, new_org), do: %{state | organization: new_org}
end
