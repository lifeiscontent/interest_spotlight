defmodule InterestSpotlightWeb.OnboardingLive.About do
  use InterestSpotlightWeb, :live_view

  alias InterestSpotlight.Profiles
  alias InterestSpotlight.Profiles.Profile

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    profile = Profiles.get_or_create_profile(user.id)
    changeset = Profile.changeset(profile, %{})

    {:ok,
     socket
     |> assign(:page_title, "Tell us more about yourself")
     |> assign(:user, user)
     |> assign(:profile, profile)
     |> assign_form(changeset)}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-md mx-auto p-4">
      <div class="flex justify-between items-center mb-4">
        <span class="text-sm text-gray-600">Step 2/2</span>
        <.link navigate={~p"/dashboard"} class="text-sm text-blue-600">Skip</.link>
      </div>

      <div class="w-full bg-gray-200 h-1 mb-6">
        <div class="bg-blue-600 h-1 w-full"></div>
      </div>

      <h1 class="text-2xl font-bold text-center mb-2">Tell us more about yourself</h1>
      <p class="text-center text-gray-600 mb-6">
        Add additional information about yourself so that other users can learn more about you.
      </p>

      <.form for={@form} phx-change="validate" phx-submit="save">
        <div class="space-y-4">
          <div>
            <label class="block text-sm font-medium mb-1">About:</label>
            <textarea
              name={@form[:bio].name}
              id={@form[:bio].id}
              rows="4"
              class="w-full border border-gray-300 rounded-lg p-3 focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              placeholder="Tell us about yourself..."
            ><%= @form[:bio].value %></textarea>
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">Add your social profiles:</label>
            <div class="space-y-3">
              <div class="flex items-center border border-gray-300 rounded-lg p-3">
                <span class="text-gray-500 mr-2">📷</span>
                <.input
                  field={@form[:instagram]}
                  placeholder="@username"
                  class="flex-1 border-0 focus:ring-0 p-0"
                />
              </div>
              <div class="flex items-center border border-gray-300 rounded-lg p-3">
                <span class="text-gray-500 mr-2">📘</span>
                <.input
                  field={@form[:facebook]}
                  placeholder="@username"
                  class="flex-1 border-0 focus:ring-0 p-0"
                />
              </div>
              <div class="flex items-center border border-gray-300 rounded-lg p-3">
                <span class="text-gray-500 mr-2">🐦</span>
                <.input
                  field={@form[:twitter]}
                  placeholder="@username"
                  class="flex-1 border-0 focus:ring-0 p-0"
                />
              </div>
              <div class="flex items-center border border-gray-300 rounded-lg p-3">
                <span class="text-gray-500 mr-2">🎵</span>
                <.input
                  field={@form[:tiktok]}
                  placeholder="@username"
                  class="flex-1 border-0 focus:ring-0 p-0"
                />
              </div>
              <div class="flex items-center border border-gray-300 rounded-lg p-3">
                <span class="text-gray-500 mr-2">▶️</span>
                <.input
                  field={@form[:youtube]}
                  placeholder="@username"
                  class="flex-1 border-0 focus:ring-0 p-0"
                />
              </div>
            </div>
          </div>
        </div>

        <div class="flex gap-4 mt-8">
          <.link
            navigate={~p"/onboarding/interests"}
            class="flex items-center justify-center w-12 h-12 rounded-lg border border-gray-300"
          >
            ←
          </.link>
          <.button type="submit" class="flex-1">
            Done
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  def handle_event("validate", %{"profile" => profile_params}, socket) do
    changeset =
      socket.assigns.profile
      |> Profile.changeset(profile_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"profile" => profile_params}, socket) do
    case Profiles.update_profile(socket.assigns.profile, profile_params) do
      {:ok, _profile} ->
        {:noreply, push_navigate(socket, to: ~p"/dashboard")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset, as: :profile))
  end
end
