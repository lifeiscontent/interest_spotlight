defmodule InterestSpotlightWeb.OnboardingLive.Interests do
  use InterestSpotlightWeb, :live_view

  alias InterestSpotlight.Interests

  @minimum_interests 3

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    all_interests = Interests.list_interests()
    selected_ids = Interests.get_user_interest_ids(user.id) |> MapSet.new()

    {:ok,
     socket
     |> assign(:page_title, "Choose your interests")
     |> assign(:user, user)
     |> assign(:interests, all_interests)
     |> assign(:selected_ids, selected_ids)
     |> assign(:minimum, @minimum_interests)}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-md mx-auto p-4">
      <div class="flex justify-between items-center mb-4">
        <span class="text-sm text-gray-600">Step 1/2</span>
        <.link navigate={~p"/onboarding/about"} class="text-sm text-blue-600">Skip</.link>
      </div>

      <div class="w-full bg-gray-200 h-1 mb-6">
        <div class="bg-blue-600 h-1 w-1/2"></div>
      </div>

      <h1 class="text-2xl font-bold text-center mb-2">Choose your interests</h1>
      <p class="text-center text-gray-600 mb-6">
        Choose at least {@minimum} interests. Later, you can change them and rate from 1 to 10 to get the most relevant recommendations.
      </p>

      <div class="flex flex-wrap gap-2 justify-center mb-8">
        <%= for interest <- @interests do %>
          <button
            type="button"
            phx-click="toggle_interest"
            phx-value-id={interest.id}
            class={"px-4 py-2 rounded-full border text-sm transition-colors " <>
              if MapSet.member?(@selected_ids, interest.id) do
                "bg-blue-600 text-white border-blue-600"
              else
                "bg-white text-gray-700 border-gray-300 hover:border-blue-400"
              end}
          >
            {interest.name}
          </button>
        <% end %>
      </div>

      <div class="mt-8">
        <button
          type="button"
          phx-click="next"
          disabled={MapSet.size(@selected_ids) < @minimum}
          class={"w-full py-3 rounded-lg font-medium transition-colors " <>
            if MapSet.size(@selected_ids) >= @minimum do
              "bg-blue-600 text-white hover:bg-blue-700"
            else
              "bg-gray-300 text-gray-500 cursor-not-allowed"
            end}
        >
          Next
        </button>
      </div>

      <p class="text-center text-sm text-gray-500 mt-4">
        Selected: {MapSet.size(@selected_ids)} / {@minimum} minimum
      </p>
    </div>
    """
  end

  def handle_event("toggle_interest", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    user = socket.assigns.user
    selected_ids = socket.assigns.selected_ids

    selected_ids =
      if MapSet.member?(selected_ids, id) do
        Interests.remove_user_interest(user.id, id)
        MapSet.delete(selected_ids, id)
      else
        Interests.add_user_interest(user.id, id)
        MapSet.put(selected_ids, id)
      end

    {:noreply, assign(socket, :selected_ids, selected_ids)}
  end

  def handle_event("next", _params, socket) do
    if MapSet.size(socket.assigns.selected_ids) >= @minimum_interests do
      {:noreply, push_navigate(socket, to: ~p"/onboarding/about")}
    else
      {:noreply, socket}
    end
  end
end
