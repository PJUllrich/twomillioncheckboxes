defmodule App.StorageFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `App.Storage` context.
  """

  @doc """
  Generate a checkboxes.
  """
  def checkboxes_fixture(attrs \\ %{}) do
    {:ok, checkboxes} =
      attrs
      |> Enum.into(%{
        checked: [1, 2]
      })
      |> App.Storage.create_checkboxes()

    checkboxes
  end
end
