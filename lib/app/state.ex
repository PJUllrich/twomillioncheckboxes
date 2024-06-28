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

  @table :game_state
  @backup_interval :timer.minutes(1)
  @max_checkboxes 2_000_000

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{}, name: @me)
  end

  def update(index) do
    GenServer.cast(@me, {:update, index, self()})
  end

  def get_checkboxes(start_index, end_index) do
    start_index = max(start_index, 0)
    end_index = min(end_index, @max_checkboxes)

    Logger.debug("Requesting checkboxes: #{inspect({start_index, end_index})}")

    Enum.map(start_index..end_index//1, fn idx -> {idx, :ets.member(@table, idx)} end)
  end

  def table_name(), do: @table

  # GenServer Callbacks

  def init(_args) do
    create_table()
    load_table()
    schedule_dump()
    {:ok, nil}
  end

  def handle_cast({:update, index, pid}, state) do
    if :ets.member(@table, index) do
      broadcast!(pid, index, false)
      :ets.delete(@table, index)
    else
      broadcast!(pid, index, true)
      :ets.insert(@table, {index, true})
    end

    {:noreply, state}
  end

  def handle_info(:dump, state) do
    schedule_dump()
    Dumper.dump(@table)
    {:noreply, state}
  end

  defp create_table() do
    :ets.new(@table, [:set, :protected, :named_table, read_concurrency: true])
  end

  defp load_table() do
    :ets.insert(@table, Storage.get_first_checkboxes_checked())
  end

  defp broadcast!(from_pid, index, value) do
    Phoenix.PubSub.broadcast_from!(
      App.PubSub,
      from_pid,
      "checkbox:update",
      {:update, index, value}
    )
  end

  defp schedule_dump() do
    Process.send_after(@me, :dump, @backup_interval)
  end
end
