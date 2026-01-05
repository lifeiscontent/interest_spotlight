defmodule InterestSpotlightWeb.HomeLive.Index do
  use InterestSpotlightWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Home
        <:subtitle>Welcome back, {@current_scope.user.email}</:subtitle>
      </.header>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
