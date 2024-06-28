defmodule App.Counter do
  alias App.State
  use GenServer

  @update_interval :timer.seconds(1)

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    table_name = State.table_name()
    schedule_update()
    {:ok, table_name}
  end

  def handle_info(:update, table_name) do
    schedule_update()
    count = table_name |> :ets.info() |> Keyword.get(:size)
    broadcast!(count)
    {:noreply, table_name}
  end

  defp schedule_update() do
    Process.send_after(__MODULE__, :update, @update_interval)
  end

  defp broadcast!(count) do
    Phoenix.PubSub.broadcast!(
      App.PubSub,
      "checkbox:update",
      {:count, count}
    )
  end
end
