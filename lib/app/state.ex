defmodule App.State do
  @moduledoc """
  A GenServer that holds the game state in memory and dumbs the state
  to the database regularly through the Dumper GenServer (arguably,
  that could have been a Task.start_link/1 call as well).
  """
  use GenServer

  require Logger

  alias App.Dumper
  alias App.Storage

  @me __MODULE__

  @backup_interval :timer.minutes(1)
  @max_checkboxes 2_000_000

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{}, name: @me)
  end

  def update(index) do
    GenServer.cast(@me, {:update, index, self()})
  end

  def load_state(start_index, end_index) do
    GenServer.call(@me, {:get, start_index, end_index})
  end

  # GenServer Callbacks

  def init(_args) do
    state = load_state()
    schedule_dump()
    {:ok, state}
  end

  def handle_cast({:update, index, pid}, state) do
    state =
      if MapSet.member?(state, index) do
        Phoenix.PubSub.broadcast_from!(
          App.PubSub,
          pid,
          "checkbox:update",
          {:update, index, false}
        )

        MapSet.delete(state, index)
      else
        Phoenix.PubSub.broadcast_from!(App.PubSub, pid, "checkbox:update", {:update, index, true})
        MapSet.put(state, index)
      end

    {:noreply, state}
  end

  def handle_call({:get, start_index, end_index}, _from, state) do
    start_index = max(start_index, 0)
    end_index = min(end_index, @max_checkboxes)

    Logger.debug("Requesting checkboxes: #{inspect({start_index, end_index})}")

    checkboxes =
      Enum.map(start_index..end_index//1, fn idx -> {idx, MapSet.member?(state, idx)} end)

    {:reply, checkboxes, state}
  end

  def handle_info(:dump, state) do
    schedule_dump()
    state |> MapSet.to_list() |> Dumper.dump()
    {:noreply, state}
  end

  defp load_state() do
    Storage.get_first_checkboxes_checked() |> MapSet.new()
  end

  defp schedule_dump() do
    Process.send_after(@me, :dump, @backup_interval)
  end
end
