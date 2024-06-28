defmodule AppWeb.Stream.Checkbox do
  use AppWeb, :live_component

  def render(assigns) do
    ~H"""
    <input type="checkbox" checked={@checked} phx-click="update" phx-value-index={@index} />
    """
  end
end
