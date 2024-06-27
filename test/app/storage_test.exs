defmodule App.StorageTest do
  use App.DataCase

  alias App.Storage

  describe "checkboxes" do
    alias App.Storage.Checkboxes

    import App.StorageFixtures

    @invalid_attrs %{checked: nil}

    test "list_checkboxes/0 returns all checkboxes" do
      checkboxes = checkboxes_fixture()
      assert Storage.list_checkboxes() == [checkboxes]
    end

    test "get_checkboxes!/1 returns the checkboxes with given id" do
      checkboxes = checkboxes_fixture()
      assert Storage.get_checkboxes!(checkboxes.id) == checkboxes
    end

    test "create_checkboxes/1 with valid data creates a checkboxes" do
      valid_attrs = %{checked: [1, 2]}

      assert {:ok, %Checkboxes{} = checkboxes} = Storage.create_checkboxes(valid_attrs)
      assert checkboxes.checked == [1, 2]
    end

    test "create_checkboxes/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Storage.create_checkboxes(@invalid_attrs)
    end

    test "update_checkboxes/2 with valid data updates the checkboxes" do
      checkboxes = checkboxes_fixture()
      update_attrs = %{checked: [1]}

      assert {:ok, %Checkboxes{} = checkboxes} =
               Storage.update_checkboxes(checkboxes, update_attrs)

      assert checkboxes.checked == [1]
    end

    test "update_checkboxes/2 with invalid data returns error changeset" do
      checkboxes = checkboxes_fixture()
      assert {:error, %Ecto.Changeset{}} = Storage.update_checkboxes(checkboxes, @invalid_attrs)
      assert checkboxes == Storage.get_checkboxes!(checkboxes.id)
    end

    test "delete_checkboxes/1 deletes the checkboxes" do
      checkboxes = checkboxes_fixture()
      assert {:ok, %Checkboxes{}} = Storage.delete_checkboxes(checkboxes)
      assert_raise Ecto.NoResultsError, fn -> Storage.get_checkboxes!(checkboxes.id) end
    end

    test "change_checkboxes/1 returns a checkboxes changeset" do
      checkboxes = checkboxes_fixture()
      assert %Ecto.Changeset{} = Storage.change_checkboxes(checkboxes)
    end
  end
end
