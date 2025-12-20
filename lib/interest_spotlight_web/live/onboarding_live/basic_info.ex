defmodule InterestSpotlightWeb.OnboardingLive.BasicInfo do
  use InterestSpotlightWeb, :live_view

  alias InterestSpotlight.Accounts
  alias InterestSpotlight.Accounts.User

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    changeset = User.onboarding_changeset(user, %{})

    {:ok,
     socket
     |> assign(:page_title, "Create account")
     |> assign(:user, user)
     |> assign_form(changeset)}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-md mx-auto p-4">
      <h1 class="text-2xl font-bold text-center mb-2">Create account</h1>
      <p class="text-center text-gray-600 mb-6">
        Please complete all information to create your account.
      </p>

      <.form for={@form} phx-change="validate" phx-submit="save">
        <div class="space-y-4">
          <div>
            <label class="block text-sm font-medium mb-1">Full name:</label>
            <.input field={@form[:first_name]} placeholder="First name" />
          </div>
          <div>
            <.input field={@form[:last_name]} placeholder="Last name" />
          </div>
          <div>
            <label class="block text-sm font-medium mb-1">City:</label>
            <.input field={@form[:location]} placeholder="City, State, Country" />
          </div>
        </div>

        <div class="mt-8">
          <.button type="submit" class="w-full">
            Create account
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.user
      |> User.onboarding_changeset(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.update_user_onboarding(socket.assigns.user, user_params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(:user, user)
         |> push_navigate(to: ~p"/onboarding/interests")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset, as: :user))
  end
end
