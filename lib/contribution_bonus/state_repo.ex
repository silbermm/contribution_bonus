defmodule ContributionBonus.StateRepo do
  @doc """
  Create the ets tables needed for saving state
  of processes. The state can be used later to 
  rehydrate a process.

  ## Examples

  iex> ContributionBonus.StateRepo.create_tables([:table1, :table2])
  {:ok, [:created, :created]}
  iex> ContributionBonus.StateRepo.create_tables([:table2, :table3])
  {:ok, [:already_exists, :created]}

  iex> ContributionBonus.StateRepo.create_tables(:needs_to_be_a_list)
  {:error, "expected a list of atoms"}
  """
  @spec create_tables(list(atom())) :: {:ok, list(atom())} | {:error, String.t()}
  def create_tables([_ | _] = table_list) do
    {:ok, Enum.map(table_list, &create_table/1)}
  end

  def create_tables(_), do: {:error, "expected a list of atoms"}

  defp create_table(table_name) do
    try do
      :ets.new(table_name, [:public, :named_table])
      :created
    rescue
      ArgumentError -> :already_exists
    end
  end
end
