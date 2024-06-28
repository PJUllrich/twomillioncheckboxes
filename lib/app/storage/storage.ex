defmodule App.Storage do
  @moduledoc """
  The Storage context.
  """

  import Ecto.Query, warn: false
  alias App.Repo

  alias App.Storage.Checkboxes

  @doc """
  Returns the list of checkboxes.

  ## Examples

      iex> list_checkboxes()
      [%Checkboxes{}, ...]

  """
  def list_checkboxes do
    Repo.all(Checkboxes)
  end

  @doc """
  Gets a single checkboxes.

  Raises `Ecto.NoResultsError` if the Checkboxes does not exist.

  ## Examples

      iex> get_checkboxes!(123)
      %Checkboxes{}

      iex> get_checkboxes!(456)
      ** (Ecto.NoResultsError)

  """
  def get_checkboxes!(id), do: Repo.get!(Checkboxes, id)

  def get_first_checkboxes(), do: Repo.get(Checkboxes, 1)

  @doc """
  Returns the list of indexes that were checked as a list of tuples
  with the format `[{123, true}, {345, true}]`
  """
  def get_first_checkboxes_checked() do
    from(cb in Checkboxes,
      where: cb.id == ^1,
      inner_lateral_join: idx in fragment("SELECT unnest(?)", cb.checked),
      on: true,
      select: fragment("(?, ?)", field(idx, :unnest), true)
    )
    |> Repo.all()
  end

  @doc """
  Creates a checkboxes.

  ## Examples

      iex> create_checkboxes(%{field: value})
      {:ok, %Checkboxes{}}

      iex> create_checkboxes(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_checkboxes(attrs \\ %{}) do
    %Checkboxes{}
    |> Checkboxes.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a checkboxes.

  ## Examples

      iex> update_checkboxes(checkboxes, %{field: new_value})
      {:ok, %Checkboxes{}}

      iex> update_checkboxes(checkboxes, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_checkboxes(%Checkboxes{} = checkboxes, attrs) do
    checkboxes
    |> Checkboxes.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a checkboxes.

  ## Examples

      iex> delete_checkboxes(checkboxes)
      {:ok, %Checkboxes{}}

      iex> delete_checkboxes(checkboxes)
      {:error, %Ecto.Changeset{}}

  """
  def delete_checkboxes(%Checkboxes{} = checkboxes) do
    Repo.delete(checkboxes)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking checkboxes changes.

  ## Examples

      iex> change_checkboxes(checkboxes)
      %Ecto.Changeset{data: %Checkboxes{}}

  """
  def change_checkboxes(%Checkboxes{} = checkboxes, attrs \\ %{}) do
    Checkboxes.changeset(checkboxes, attrs)
  end
end
