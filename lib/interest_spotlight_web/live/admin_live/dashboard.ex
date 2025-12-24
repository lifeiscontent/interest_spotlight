defmodule InterestSpotlightWeb.AdminLive.Dashboard do
  use InterestSpotlightWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Admin Dashboard")}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto p-4">
      <h1 class="text-2xl font-bold mb-6">Admin Dashboard</h1>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <.link
          navigate={~p"/admin/interests"}
          class="block p-6 bg-white rounded-lg border border-gray-200 hover:bg-gray-50"
        >
          <h2 class="text-lg font-semibold mb-2">Manage Interests</h2>
          <p class="text-gray-600">Add, edit, or remove interests that users can select.</p>
        </.link>
      </div>
    </div>
    """
  end
end
