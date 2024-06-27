defmodule AppWeb.PageLive do
  use AppWeb, :live_view

  alias App.State

  @impl true
  def mount(_params, _session, socket) do
    checkboxes = if connected?(socket), do: State.load_state(1, 2000), else: []
    {:ok, assign(socket, :checkboxes, checkboxes)}
  end

  @impl true
  def handle_event("update", %{"value" => index}, socket) do
    index |> String.to_integer() |> State.update()
    {:noreply, socket}
  end
end
