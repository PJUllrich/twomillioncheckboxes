defmodule App.Repo.Migrations.CreateCheckboxes do
  use Ecto.Migration

  def change do
    create table(:checkboxes) do
      add :checked, {:array, :integer}, default: []

      timestamps(type: :utc_datetime)
    end
  end
end
