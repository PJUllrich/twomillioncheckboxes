defmodule AppWeb.PageLive do
  use AppWeb, :live_view

  alias App.State

  alias AppWeb.Components.Checkbox

  @per_page 3000
  @page_padding 500

  @impl true
  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        start_idx: 0,
        end_idx: @per_page,
        end_of_board?: false,
        checkboxes: []
      )

    socket =
      if connected?(socket) do
        Phoenix.PubSub.subscribe(App.PubSub, "checkbox:update")
        fetch_checkboxes(socket)
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
  def handle_event("jump", %{"index" => index}, socket) do
    socket =
      case Integer.parse(index) do
        {index, ""} ->
          socket

        _ ->
          socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("next-page", _, socket) do
    {:noreply, socket |> update_indexes(@per_page) |> fetch_checkboxes()}
  end

  @impl true
  def handle_event("prev-page", _, socket) do
    if socket.assigns.start_idx > 0 do
      {:noreply, socket |> update_indexes(-@per_page) |> fetch_checkboxes()}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:checkbox_update, _idx, _value}, socket) do
    {:noreply}
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
