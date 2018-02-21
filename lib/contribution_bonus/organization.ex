defmodule ContributionBonus.Organization do
  alias __MODULE__
  alias ContributionBonus.Member

  defstruct name: nil, members: []

  def new(name) do
    {:ok, %Organization{name: name}}
  end

  def add_member(%Organization{name: name, members: members} = org, %Member{} = member)
      when not is_nil(name) do
    to_add = Enum.any?(org.members, &(&1.email == member.email))
    _add_member(org, member, members, to_add)
  end

  def add_member(_org, _member), do: :error

  def _add_member(org, member, current, false),
    do: %{org | members: Enum.concat(current, [member])}

  def _add_member(_organization, _member, _current, true), do: {:error, "already exists"}
end
