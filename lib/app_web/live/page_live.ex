defmodule AppWeb.PageLive do
  use AppWeb, :live_view

  alias App.State

  alias AppWeb.Components.Checkbox

  @presence_channel "game"

  @start_count 3000
  @fetch_count 500

  @impl true
  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        start_idx: 0,
        end_idx: @start_count,
        end_of_board?: false,
        user_count: 1,
        checkboxes: []
      )

    socket =
      if connected?(socket) do
        {:ok, _} =
          AppWeb.Presence.track(self(), @presence_channel, socket.id, %{
            joined_at: :os.system_time(:seconds)
          })

        user_count = AppWeb.Presence.list(@presence_channel) |> map_size()

        Phoenix.PubSub.subscribe(App.PubSub, @presence_channel)
        Phoenix.PubSub.subscribe(App.PubSub, "checkbox:update")
        socket |> assign(user_count: user_count) |> fetch_checkboxes()
      else
        socket
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("update", %{"value" => index}, socket) do
    index |> String.to_integer() |> State.update()
    {:noreply, socket}
  end

  @impl true
  def handle_event("update", _, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("jump", %{"index" => index}, socket) do
    socket =
      case Integer.parse(index) do
        {index, ""} ->
          start_idx = ((index / @start_count) |> Float.floor() |> trunc()) * @start_count
          end_idx = start_idx + @start_count
          socket |> assign(start_idx: start_idx, end_idx: end_idx) |> fetch_checkboxes()

        _ ->
          socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("next-page", _, socket) do
    {:noreply, socket |> update_indexes(@fetch_count) |> fetch_checkboxes()}
  end

  @impl true
  def handle_event("prev-page", _, socket) do
    if socket.assigns.start_idx > 0 do
      {:noreply, socket |> update_indexes(-@fetch_count) |> fetch_checkboxes()}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, socket) do
    # Ignore the own join. Otherwise, this might be off-by-one.
    joins = Map.delete(diff.joins, self())
    diff_count = map_size(joins) - map_size(diff.leaves)

    {
      :noreply,
      update(socket, :user_count, fn old_count -> old_count + diff_count end)
    }
  end

  @impl true
  def handle_info({:update, idx, value}, socket) do
    checkboxes =
      Enum.map(socket.assigns.checkboxes, fn
        {^idx, _value} -> {idx, value}
        entry -> entry
      end)

    {:noreply, assign(socket, :checkboxes, checkboxes)}
  end

  def fetch_checkboxes(socket) do
    %{start_idx: start_idx, end_idx: end_idx} = socket.assigns
    checkboxes = State.load_state(start_idx, end_idx)
    assign(socket, :checkboxes, checkboxes)
  end

  defp update_indexes(socket, amount) do
    %{start_idx: start_idx, end_idx: end_idx} = socket.assigns
    assign(socket, start_idx: start_idx + amount, end_idx: end_idx + amount)
  end
end
