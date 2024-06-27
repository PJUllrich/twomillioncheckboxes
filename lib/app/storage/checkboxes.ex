defmodule App.Storage.Checkboxes do
  use Ecto.Schema
  import Ecto.Changeset

  schema "checkboxes" do
    field :checked, {:array, :integer}, default: [], load_in_query: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(checkboxes, attrs) do
    checkboxes
    |> cast(attrs, [:checked])
    |> validate_required([:checked])
  end
end
