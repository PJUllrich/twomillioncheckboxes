defmodule App.Dumper do
  @moduledoc """
  Dumps the game state into the database.
  """
  use GenServer
  require Logger

  alias App.Storage

  @me __MODULE__

  def start_link(_args) do
    GenServer.start_link(@me, nil, name: @me)
  end

  def dump(checked) when is_list(checked) do
    GenServer.cast(@me, {:dump, checked})
  end

  # GenServer Callbacks

  def init(_args) do
    {:ok, nil}
  end

  def handle_cast({:dump, checked}, state) when is_list(checked) do
    Logger.info("Dumping...")

    {:ok, _checkboxes} =
      case Storage.get_first_checkboxes() do
        nil -> Storage.create_checkboxes(%{checked: checked})
        checkboxes -> Storage.update_checkboxes(checkboxes, %{checked: checked})
      end

    {:noreply, state}
  end
end
