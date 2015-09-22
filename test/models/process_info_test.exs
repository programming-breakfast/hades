defmodule Hades.ProcessInfoTest do
  use Hades.ModelCase

  alias Hades.ProcessInfo

  @valid_attrs %{cpu_percent: "120.5", cpu_system: "120.5", cpu_user: "120.5", created_at: "2010-04-17 14:00:00", memory_pageins: 42, memory_pfaults: 42, memory_rss: 42, memory_vms: 42, name: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = ProcessInfo.changeset(%ProcessInfo{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = ProcessInfo.changeset(%ProcessInfo{}, @invalid_attrs)
    refute changeset.valid?
  end
end
