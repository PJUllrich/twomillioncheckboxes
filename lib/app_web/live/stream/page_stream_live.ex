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

  @inital_size 1500
  @page_size 500
  @limit @inital_size + @page_size

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(
        page: 1,
        page_size: @page_size,
        inital_size: @inital_size,
        end_of_board?: false,
        column_count: 20,
        user_count: 0,
        checked_count: State.get_checked_count()
      )
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
        socket |> assign(user_count: user_count) |> paginate_checkboxes(1, @inital_size)
      else
        socket
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("column-count", column_count, socket) do
    {:noreply, assign(socket, :column_count, column_count)}
  end

  @impl true
  def handle_event("update", %{"index" => index}, socket) do
    with {index, ""} <- Integer.parse(index) do
      State.update(index)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("jump", %{"index" => index}, socket) do
    socket =
      case Integer.parse(index) do
        {index, ""} ->
          new_page = (index / @page_size) |> Float.ceil() |> trunc()
          # Load three pages of data, which is equal to the initial size
          paginate_checkboxes(socket, new_page - 2, @inital_size, true)

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
    if socket.assigns.page <= 5 do
      {:noreply, paginate_checkboxes(socket, 1)}
    else
      {:noreply, socket}
    end
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
  def handle_info({:update, index, value, checked_count}, socket) do
    cur_page = socket.assigns.page
    end_idx = cur_page * @page_size
    start_idx = end_idx - @limit

    socket =
      if index in start_idx..end_idx//1 do
        stream_insert(socket, :checkboxes, {index, value})
      else
        socket
      end

    socket =
      if Enum.random(1..10//1) == 1 do
        assign(socket, :checked_count, checked_count)
      else
        socket
      end

    {:noreply, socket}
  end

  defp paginate_checkboxes(socket, new_page, custom_limit \\ nil, reset \\ false)

  defp paginate_checkboxes(socket, new_page, custom_limit, reset)
       when new_page >= 1 do
    %{page: cur_page, column_count: column_count} = socket.assigns

    start_idx = max((new_page - 1) * @page_size, 0)
    end_idx = if custom_limit, do: start_idx + custom_limit, else: new_page * @page_size

    # Only fetch "full" rows of data so that the board doesn't shift.
    # If we'd e.g. show 20 checkboxes in a 5x4 grid, then add 7 and remove 7,
    # the board would shift to the left by 2 (7 - 5) checkboxes. This here
    # allows us to only fetch and remove 5 checkboxes, which would keep the
    # current layout
    diff = end_idx - start_idx
    end_idx = end_idx - rem(diff, column_count) - 1

    checkboxes = State.get_checkboxes(start_idx, end_idx)

    {checkboxes, at, limit} =
      if new_page >= cur_page do
        {checkboxes, -1, -@limit}
      else
        {Enum.reverse(checkboxes), 0, @limit}
      end

    case checkboxes do
      [] ->
        assign(socket, end_of_board?: at == -1)

      _ ->
        socket
        |> assign(end_of_board?: false)
        |> assign(:page, new_page)
        |> stream(:checkboxes, checkboxes, at: at, reset: reset, limit: limit)
    end
  end

  defp paginate_checkboxes(socket, _new_page, _custom_limit, _reset), do: socket
end
