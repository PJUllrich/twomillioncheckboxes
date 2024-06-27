defmodule AppWeb.Components.Checkbox do
  use AppWeb, :html

  attr :index, :integer, required: true
  attr :value, :boolean, required: true

  def show(assigns) do
    ~H"""
    <input id={"c#{@index}"} type="checkbox" value={@index} checked={@value} phx-click="update" />
    """
  end
end
