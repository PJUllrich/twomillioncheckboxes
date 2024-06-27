defmodule App.State do
  alias App.Dumper
  alias App.Storage
  use GenServer

  @me __MODULE__
  @backup_interval :timer.seconds(10)

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{}, name: @me)
  end

  def update(index) do
    GenServer.cast(@me, {:update, index})
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

  def handle_cast({:update, index}, state) do
    state =
      if Map.has_key?(state, index) do
        Map.delete(state, index)
      else
        Map.put(state, index, true)
      end

    {:noreply, state}
  end

  def handle_call({:get, start_index, end_index}, _from, state) do
    keys = Enum.to_list(start_index..end_index//1)
    fields = keys |> Enum.map(fn idx -> {idx, false} end) |> Map.new()
    values = Map.take(state, keys)
    checkboxes = Map.merge(fields, values)

    {:reply, checkboxes, state}
  end

  def handle_info(:dump, state) do
    schedule_dump()
    state |> Map.keys() |> Dumper.dump()
    {:noreply, state}
  end

  defp load_state() do
    Storage.get_first_checkboxes_checked() |> Map.from_keys(true)
  end

  defp schedule_dump() do
    Process.send_after(@me, :dump, @backup_interval)
  end
end
