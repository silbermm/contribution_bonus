defmodule ContributionBonus.StateRepoTest do
  use ExUnit.Case

  alias ContributionBonus.StateRepo
  doctest ContributionBonus.StateRepo

  @table_exists :table_exists

  describe "creates tables" do
    test "fails for empty list" do
      assert {:error, "expected a non-empty list"} == StateRepo.create_tables([])
    end

    test "fails when not a list" do
      assert {:error, "expected a list of atoms"} == StateRepo.create_tables(:no_list_here)
    end

    test "when list of atoms" do
      assert {:ok, [:created]} == StateRepo.create_tables([:test_success])
      # cleanup
      :ets.delete(:test_success)
    end

    test "returns status of each table" do
      assert {:ok, [:created]} == StateRepo.create_tables([:test_success])

      assert {:ok, [:created, :already_exists]} ==
               StateRepo.create_tables([:test_another, :test_success])

      # cleanup
      :ets.delete(:test_success)
      # cleanup
      :ets.delete(:test_another)
    end
  end

  test "inserts data correctly" do
    StateRepo.create_tables([@table_exists])
    res = StateRepo.update(@table_exists, {:key1, ["value1", "value2"]})
    assert res == :ok
  end
end
