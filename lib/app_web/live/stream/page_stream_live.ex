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

  @max_checkboxes 2_000_000
  @page_size_fraction_of_page 5

  require Logger

  alias App.State

  alias AppWeb.Stream.Checkbox

  @presence_channel "game"

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(
        page: 0,
        end_of_board?: false,
        column_count: 20,
        row_count: 0,
        user_count: 0,
        checked_count: 0,
        limit: 0,
        start_idx: 0,
        end_idx: 0
      )
      |> stream_configure(:checkboxes, dom_id: fn {idx, _value} -> "c#{idx}" end)
      # We need to render one checkbox at the start to calculate its height in the phx hook.
      |> stream(:checkboxes, [{0, true}])

    socket =
      if connected?(socket) do
        {:ok, _} =
          AppWeb.Presence.track(self(), @presence_channel, socket.id, %{
            joined_at: :os.system_time(:seconds)
          })

        user_count = AppWeb.Presence.list(@presence_channel) |> map_size()
        Phoenix.PubSub.subscribe(App.PubSub, @presence_channel)
        Phoenix.PubSub.subscribe(App.PubSub, "checkbox:update")
        assign(socket, user_count: user_count)
      else
        socket
      end

    {:ok, socket}
  end

  @impl true
  def handle_event(
        "column-count",
        %{"columnCount" => column_count, "rowCount" => row_count},
        socket
      ) do
    {:noreply,
     socket
     |> assign(
       column_count: column_count,
       row_count: row_count,
       start_idx: 0,
       end_idx: column_count * row_count,
       limit: column_count * row_count,
       page_size: trunc(row_count / @page_size_fraction_of_page) * column_count
     )
     |> paginate_checkboxes(0, true, true)}
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
    %{page_size: page_size, column_count: column_count, row_count: row_count} = socket.assigns

    socket =
      case Integer.parse(index) do
        {index, ""} ->
          initial_page_size = column_count * row_count
          new_page = ((index / page_size) |> trunc()) - 3

          socket
          |> assign(
            start_idx: new_page * page_size,
            end_idx: new_page * page_size + initial_page_size,
            page: new_page
          )
          |> paginate_checkboxes(new_page, true, true)

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
  def handle_event("prev-page", _, socket) do
    {:noreply, paginate_checkboxes(socket, socket.assigns.page - 1)}
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
  def handle_info({:update, index, value}, socket) do
    %{start_idx: start_idx, end_idx: end_idx} = socket.assigns

    if index in start_idx..end_idx//1 do
      send_update(Checkbox, id: "c#{index}", checked: value)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:count, count}, socket) do
    {:noreply, assign(socket, :checked_count, count)}
  end

  defp paginate_checkboxes(socket, new_page, initial_load \\ false, reset \\ false)

  defp paginate_checkboxes(socket, -1, _initial_load, _reset) do
    paginate_checkboxes(socket, 0, true, true)
  end

  defp paginate_checkboxes(socket, new_page, initial_load, reset) do
    %{
      page: cur_page,
      column_count: column_count,
      row_count: row_count,
      limit: limit,
      start_idx: start_idx,
      end_idx: end_idx,
      page_size: page_size
    } = socket.assigns

    # Only fetch "full" rows of data so that the board doesn't shift.
    # If we'd e.g. show 20 checkboxes in a 5x4 grid, then add 7 and remove 7,
    # the board would shift to the left by 2 (7 - 5) checkboxes. This here
    # allows us to only fetch and remove 5 checkboxes, which would keep the
    # current layout

    # Let the page size depend on how many columns are displayed
    scrolling_down? = new_page >= cur_page

    {start_idx, end_idx, fetch_start, fetch_end, at, adj_limit} =
      cond do
        initial_load ->
          # New Start Index, New End Index, Fetch Start, Fetch End, At, Limit
          {start_idx, end_idx - 1, start_idx, end_idx - 1, -1, -limit}

        scrolling_down? ->
          {
            start_idx + page_size,
            end_idx + page_size,
            end_idx + 1,
            end_idx + page_size,
            -1,
            -limit
          }

        !scrolling_down? ->
          {
            start_idx - page_size,
            end_idx - page_size,
            start_idx - page_size,
            start_idx - 1,
            0,
            limit
          }
      end

    start_idx = sanitize(start_idx)
    end_idx = sanitize(end_idx)
    fetch_start = sanitize(fetch_start)
    fetch_end = sanitize(fetch_end)

    checkboxes = State.get_checkboxes(fetch_start, fetch_end)
    checkboxes = if scrolling_down?, do: checkboxes, else: Enum.reverse(checkboxes)

    Logger.debug(
      old_page: cur_page,
      new_page: new_page,
      start_idx: start_idx,
      end_idx: end_idx,
      fetch_start: fetch_start,
      fetch_end: fetch_end,
      row_count: row_count,
      column_count: column_count,
      page_size: page_size,
      adj_limit: adj_limit,
      length: length(checkboxes)
    )

    case checkboxes do
      [] ->
        assign(socket, end_of_board?: at == -1)

      _ ->
        socket
        |> assign(end_of_board?: false, page: new_page, start_idx: start_idx, end_idx: end_idx)
        |> stream(:checkboxes, checkboxes, at: at, reset: reset, limit: adj_limit)
    end
  end

  defp sanitize(idx) do
    idx |> max(0) |> min(@max_checkboxes)
  end
end
