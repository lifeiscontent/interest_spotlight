defmodule InterestSpotlightWeb.AdminLive.Dashboard do
  use InterestSpotlightWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Admin Dashboard")}
  end

  def render(assigns) do
    ~H"""
    <Layouts.admin_app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-4xl mx-auto">
        <h1 class="text-2xl font-bold mb-6">Admin Dashboard</h1>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <.link
            navigate={~p"/admins/interests"}
            class="block p-6 bg-base-100 rounded-lg border border-base-300 hover:bg-base-200"
          >
            <h2 class="text-lg font-semibold mb-2">Manage Interests</h2>
            <p class="text-base-content/70">Add, edit, or remove interests that users can select.</p>
          </.link>
        </div>
      </div>
    </Layouts.admin_app>
    """
  end
end
