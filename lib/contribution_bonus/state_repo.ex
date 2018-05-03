defmodule ContributionBonus.StateRepo do

  @doc """
  Create the ets tables needed for saving state
  of processes. The state can be used later to 
  rehydrate a process.
  """
  def create_tables(table_list) do
    Enum.map(table_list, &create_table/1)
  end


  defp create_table(table_name) do
    try do
      :ets.new(table_name, [:public, :named_table])
      :created
    rescue
      ArgumentError -> :already_exists
    end
  end

end
