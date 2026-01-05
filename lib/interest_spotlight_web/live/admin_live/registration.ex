defmodule InterestSpotlightWeb.AdminLive.Registration do
  use InterestSpotlightWeb, :live_view

  alias InterestSpotlight.Backoffice
  alias InterestSpotlight.Backoffice.Admin

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm">
        <div class="text-center">
          <.header>
            Register for an account
            <:subtitle>
              Already registered?
              <.link navigate={~p"/admins/log-in"} class="font-semibold text-brand hover:underline">
                Log in
              </.link>
              to your account now.
            </:subtitle>
          </.header>
        </div>

        <.form for={@form} id="registration_form" phx-submit="save" phx-change="validate">
          <.input
            field={@form[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            required
            phx-mounted={JS.focus()}
          />

          <.button phx-disable-with="Creating account..." class="btn btn-primary w-full">
            Create an account
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{admin: admin}}} = socket)
      when not is_nil(admin) do
    {:ok, redirect(socket, to: InterestSpotlightWeb.AdminAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = Backoffice.change_admin_email(%Admin{}, %{}, validate_unique: false)

    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"admin" => admin_params}, socket) do
    case Backoffice.register_admin(admin_params) do
      {:ok, admin} ->
        {:ok, _} =
          Backoffice.deliver_login_instructions(
            admin,
            &url(~p"/admins/log-in/#{&1}")
          )

        {:noreply,
         socket
         |> put_flash(
           :info,
           "An email was sent to #{admin.email}, please access it to confirm your account."
         )
         |> push_navigate(to: ~p"/admins/log-in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"admin" => admin_params}, socket) do
    changeset = Backoffice.change_admin_email(%Admin{}, admin_params, validate_unique: false)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "admin")
    assign(socket, form: form)
  end
end
