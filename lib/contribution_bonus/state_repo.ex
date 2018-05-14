defmodule ContributionBonus.StateRepo do
  @moduledoc """
  Manage the ets tables used for saving the
  state of the organization and contribution
  processes. The state can be used later to
  rehydrate a process.
  """

  @doc """
  Create the ets tables needed for saving state
  of processes.

  ## Examples

  iex> ContributionBonus.StateRepo.create_tables([:table1, :table2])
  {:ok, [:created, :created]}
  iex> ContributionBonus.StateRepo.create_tables([:table2, :table3])
  {:ok, [:already_exists, :created]}

  """
  @spec create_tables(list(atom())) :: {:ok, list(atom())} | {:error, String.t()}
  def create_tables([_ | _] = table_list) do
    {:ok, Enum.map(table_list, &create_table/1)}
  end

  def create_tables([]), do: {:error, "expected a non-empty list"}

  def create_tables(_), do: {:error, "expected a list of atoms"}

  @spec update(atom(), {atom(), any()}) :: :ok | {:error, String.t()}
  def update(table, {key, data} = payload) do
    try do
      table
      |> :ets.insert(payload)
      |> case do
        true -> :ok
        false -> {:error, "unable to insert data"}
      end
    rescue
      ArgumentError -> {:error, "table does not exist"}
    end
  end

  def update(table, _payload), do: {:error, "incorrect payload format"}

  @spec find(atom(), atom()) :: list()
  def find(table, key) do
    :ets.lookup(table, key)
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
