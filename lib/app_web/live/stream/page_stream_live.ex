defmodule AppWeb.PageStreamLive do
  @moduledoc """
  This was my first impementation using LiveView Streams.
  The problem here are that:

    1. Deleting elements from the DOM leads to a significant delay and would
    lead to weird DOM changes.

    2. Updating single checkboxes when an update comes in isn't easily possible.
    Maybe this could be fixed by using LiveComponents of groups of checkboxes
    intelligently, but I gave up at that point.

  """
  use AppWeb, :live_view

  alias App.State

  @presence_channel "game"

  @page_size 500

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(page: 1, page_size: @page_size, end_of_board?: false, user_count: 0)
      |> stream_configure(:checkboxes, dom_id: fn {idx, _value} -> "c#{idx}" end)
      |> stream(:checkboxes, [])

    socket =
      if connected?(socket) do
        {:ok, _} =
          AppWeb.Presence.track(self(), @presence_channel, socket.id, %{
            joined_at: :os.system_time(:seconds)
          })

        user_count = AppWeb.Presence.list(@presence_channel) |> map_size()
        Phoenix.PubSub.subscribe(App.PubSub, @presence_channel)
        Phoenix.PubSub.subscribe(App.PubSub, "checkbox:update")
        socket |> assign(user_count: user_count) |> paginate_checkboxes(1)
      else
        socket
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("update", %{"index" => index}, socket) do
    index |> String.to_integer() |> State.update()
    {:noreply, socket}
  end

  @impl true
  def handle_event("jump", %{"index" => index}, socket) do
    socket =
      case Integer.parse(index) do
        {index, ""} ->
          new_page = (index / @page_size) |> Float.ceil() |> trunc()
          paginate_checkboxes(socket, new_page, true)

        _ ->
          socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("next-page", _, socket) do
    {:noreply, paginate_checkboxes(socket, socket.assigns.page + 1)}
  end

  def handle_event("prev-page", %{"_overran" => true}, socket) do
    {:noreply, paginate_checkboxes(socket, 1)}
  end

  @impl true
  def handle_event("prev-page", _, socket) do
    if socket.assigns.page > 1 do
      {:noreply, paginate_checkboxes(socket, socket.assigns.page - 1)}
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
    # How could we update the stream elements?
    # We probably would need to make every checkbox a single LiveComponent,
    # but that'll blow up the browser and our server.
    # Maybe chunking the checkboxes into e.g. groups of 1000 might help.
    {:noreply, stream_insert(socket, :checkboxes, {idx, value})}
  end

  defp paginate_checkboxes(socket, new_page, reset \\ false)
       when new_page >= 1 do
    %{page_size: page_size, page: cur_page} = socket.assigns

    start_idx = max((new_page - 1) * page_size, 0)
    end_idx = new_page * page_size

    checkboxes = State.load_state(start_idx, end_idx)

    {checkboxes, at, limit} =
      if new_page >= cur_page do
        {checkboxes, -1, page_size * 3 - 1}
      else
        {Enum.reverse(checkboxes), 0, page_size * 3}
      end

    case checkboxes do
      [] ->
        assign(socket, end_of_board?: at == -1)

      _ ->
        socket
        |> assign(end_of_board?: false)
        |> assign(:page, new_page)
        # If you add limit: limit here, all hell will break loose in the frontend
        # Every update will take a few seconds until the checkboxes are rendered client-side
        # State updates go from 6-10ms to ~1s for removing and adding the new elements.
        |> stream(:checkboxes, checkboxes, at: at, reset: reset, limit: limit)
    end
  end
end
