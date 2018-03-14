defmodule ContributionBonus.MemberTest do
  use ExUnit.Case, async: true

  alias ContributionBonus.Member

  test "creates a new member" do
    assert {:ok, %Member{first_name: "Matt", last_name: "Silbernagel", email: "m.s@ingagepartners.com"}} ==
      Member.new("Matt", "Silbernagel", "m.s@ingagepartners.com")
  end

  test "requires non-nil first_name" do
    {:error, _} = Member.new(nil, "Silbernagel", "m.s@ingagepartners.com")
  end

  test "requires non-nil last_name" do
    {:error, _} = Member.new("Matt", nil, "m.s@ingagepartners.com")
  end

  test "requires non-nil email" do
    {:error, _} = Member.new("Matt", "silbernagel", nil)
  end
end
