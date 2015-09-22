defmodule Hades.Repo.Migrations.CreateProcessInfo do
  use Ecto.Migration

  def change do
    create table(:process_infos) do
      add :name, :string
      add :cpu_user, :float
      add :cpu_system, :float
      add :cpu_percent, :float
      add :memory_pageins, :integer
      add :memory_pfaults, :integer
      add :memory_rss, :integer
      add :memory_vms, :integer

      timestamps
    end

    create index(:process_infos, [:inserted_at, :name])
  end
end
