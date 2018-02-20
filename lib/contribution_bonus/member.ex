defmodule ContributionBonus.Member do
  alias __MODULE__

  @enforce_keys [:first_name, :last_name, :email]
  defstruct [:first_name, :last_name, :email]

  def new(first_name, last_name, email) do
    case assert_non_empty([first_name, last_name, email]) do
      true -> {:ok, %Member{first_name: first_name, last_name: last_name, email: email}}
      _ -> {:error, "non empty first_name, last_name and email expected"}
    end
  end

  defp assert_non_empty(arr), do: Enum.all?(arr, &(&1 != "" and &1 != nil))
end
