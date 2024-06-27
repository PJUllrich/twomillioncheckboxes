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

  @start_page 4000
  @per_page 2000

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(page: 1, per_page: @per_page)
      |> stream_configure(:checkboxes, dom_id: fn {idx, _value} -> "c#{idx}" end)
      |> paginate_checkboxes(1, @start_page)

    if connected?(socket), do: Phoenix.PubSub.subscribe(App.PubSub, "checkbox:update")

    {:ok, socket}
  end

  @impl true
  def handle_event("update", %{"value" => index}, socket) do
    index |> String.to_integer() |> State.update()
    {:noreply, socket}
  end

  @impl true
  def handle_event("jump", %{"index" => index}, socket) do
    socket =
      case Integer.parse(index) do
        {index, ""} ->
          new_page = (index / @per_page) |> Float.ceil() |> trunc()
          paginate_checkboxes(socket, new_page, @start_page, true)

        _ ->
          socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("next-page", _, socket) do
    {:noreply, paginate_checkboxes(socket, socket.assigns.page + 1)}
  end

  @impl true
  def handle_event("prev-page", %{"_overran" => true}, socket) do
    {:noreply, socket}
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
  def handle_info({:checkbox_update, _idx, _value}, socket) do
    # How could we update the stream elements?
    # We probably would need to make every checkbox a single LiveComponent,
    # but that'll blow up the browser and our server.
    # Maybe chunking the checkboxes into e.g. groups of 1000 might help.
    {:noreply}
  end

  defp paginate_checkboxes(socket, new_page, custom_limit \\ nil, reset \\ false)
       when new_page >= 1 do
    %{per_page: per_page, page: cur_page} = socket.assigns
    start_idx = (new_page - 1) * per_page
    end_idx = if custom_limit, do: start_idx + custom_limit, else: new_page * per_page
    checkboxes = State.load_state(start_idx, end_idx)

    {checkboxes, at, _limit} =
      if new_page >= cur_page do
        {checkboxes, -1, per_page * 2 - 1}
      else
        {Enum.reverse(checkboxes), 0, per_page * 2}
      end

    case checkboxes do
      [] ->
        assign(socket, end_of_board?: at == -1)

      _ ->
        socket
        |> assign(end_of_board?: false)
        |> assign(:page, new_page)
        |> assign(:start_idx, start_idx)
        |> assign(:end_idx, end_idx)
        # If you add limit: limit here, all hell will break loose in the frontend
        # Every update will take a few seconds until the checkboxes are rendered client-side
        # State updates go from 6-10ms to ~1s for removing and adding the new elements.
        |> stream(:checkboxes, checkboxes, at: at, reset: reset)
    end
  end
end
