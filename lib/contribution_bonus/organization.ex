defmodule ContributionBonus.Organization do
  alias __MODULE__
  alias ContributionBonus.Member

  defstruct name: nil, members: []

  def new(name) do
    {:ok, %Organization{name: name}}
  end

  def add_member(%Organization{name: name, members: members} = org, %Member{} = member)
      when not is_nil(name) do
    %{org | members: Enum.concat(members, [member])}
  end

  def add_member(_org, member), do: :error
end
