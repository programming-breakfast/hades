defmodule Hades.ProcessInfo do
  use Hades.Web, :model

  schema "process_infos" do
    field :name, :string
    field :cpu_user, :float
    field :cpu_system, :float
    field :cpu_percent, :float
    field :memory_pageins, :integer
    field :memory_pfaults, :integer
    field :memory_rss, :integer
    field :memory_vms, :integer

    timestamps
  end

  @required_fields ~w(name cpu_user cpu_system cpu_percent memory_pageins memory_pfaults memory_rss memory_vms)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

  def find_by_name(name) do
    {:ok, inserted_at} = Timex.Date.now
    |> Timex.Date.subtract(Timex.Time.to_timestamp(2, :secs))
    |> Timex.DateFormat.format("{ISO}")

    (
      from p in Hades.ProcessInfo,
      where: p.name == ^name,
      where: p.inserted_at > ^inserted_at,
      order_by: [desc: p.inserted_at],
      limit: 1,
      select: p
    )
    |> Hades.Repo.one
  end
end
