defmodule InterestSpotlightWeb.ProfileLive do
  use InterestSpotlightWeb, :live_view

  alias InterestSpotlight.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-2xl mx-auto">
        <.header>
          Profile
          <:subtitle>Manage your profile information</:subtitle>
        </.header>

        <div class="mt-8 space-y-8">
          <%!-- Profile Photo Section --%>
          <div class="card bg-base-200 p-6">
            <h3 class="text-lg font-semibold mb-4">Profile Photo</h3>

            <div class="flex items-start gap-6">
              <%!-- Current Photo or Placeholder --%>
              <div class="flex-shrink-0">
                <%= if @user.profile_photo do %>
                  <img
                    src={"/uploads/#{@user.profile_photo}"}
                    alt="Profile photo"
                    class="w-32 h-32 rounded-full object-cover border-4 border-base-300"
                  />
                <% else %>
                  <div class="w-32 h-32 rounded-full bg-base-300 flex items-center justify-center">
                    <.icon name="hero-user" class="w-16 h-16 text-base-content/50" />
                  </div>
                <% end %>
              </div>

              <%!-- Upload Form --%>
              <div class="flex-1 space-y-4">
                <form id="upload-form" phx-submit="upload_photo" phx-change="validate">
                  <div class="space-y-2">
                    <.live_file_input
                      upload={@uploads.photo}
                      class="file-input file-input-bordered w-full"
                    />

                    <%= for entry <- @uploads.photo.entries do %>
                      <div class="flex items-center gap-2 p-2 bg-base-100 rounded-lg">
                        <.live_img_preview entry={entry} class="w-12 h-12 rounded object-cover" />
                        <div class="flex-1">
                          <p class="text-sm font-medium truncate">{entry.client_name}</p>
                          <progress
                            class="progress progress-primary w-full"
                            value={entry.progress}
                            max="100"
                          >
                            {entry.progress}%
                          </progress>
                        </div>
                        <button
                          type="button"
                          phx-click="cancel_upload"
                          phx-value-ref={entry.ref}
                          class="btn btn-ghost btn-sm btn-circle"
                          aria-label="cancel"
                        >
                          <.icon name="hero-x-mark" class="w-4 h-4" />
                        </button>
                      </div>

                      <%= for err <- upload_errors(@uploads.photo, entry) do %>
                        <p class="text-error text-sm">{error_to_string(err)}</p>
                      <% end %>
                    <% end %>

                    <%= for err <- upload_errors(@uploads.photo) do %>
                      <p class="text-error text-sm">{error_to_string(err)}</p>
                    <% end %>
                  </div>

                  <div class="flex gap-2 mt-4">
                    <button
                      type="submit"
                      class={[
                        "btn btn-primary",
                        @uploads.photo.entries == [] && "btn-disabled"
                      ]}
                      disabled={@uploads.photo.entries == []}
                    >
                      <.icon name="hero-arrow-up-tray" class="w-4 h-4" /> Upload Photo
                    </button>

                    <%= if @user.profile_photo do %>
                      <button
                        type="button"
                        phx-click="delete_photo"
                        data-confirm="Are you sure you want to delete your profile photo?"
                        class="btn btn-error btn-outline"
                      >
                        <.icon name="hero-trash" class="w-4 h-4" /> Delete
                      </button>
                    <% end %>
                  </div>
                </form>

                <p class="text-sm text-base-content/70">
                  Supported formats: JPG, JPEG, PNG. Max size: 5MB.
                </p>
              </div>
            </div>
          </div>

          <%!-- Profile Visibility Section --%>
          <div class="card bg-base-200 p-6">
            <h3 class="text-lg font-semibold mb-4">Profile Visibility</h3>
            <p class="text-sm text-base-content/70 mb-4">
              Control who can see your profile information (interests, bio, social links).
            </p>

            <div class="form-control">
              <label class="label cursor-pointer justify-start gap-4">
                <input
                  type="checkbox"
                  id="profile-visibility-toggle"
                  class="toggle toggle-primary"
                  checked={@user.profile_visibility == "public"}
                  phx-click="toggle_visibility"
                />
                <div>
                  <span class="label-text font-medium">
                    <%= if @user.profile_visibility == "public" do %>
                      <.icon name="hero-globe-alt" class="w-4 h-4 inline" /> Public Profile
                    <% else %>
                      <.icon name="hero-lock-closed" class="w-4 h-4 inline" /> Private Profile
                    <% end %>
                  </span>
                  <p class="text-xs text-base-content/60 mt-1">
                    <%= if @user.profile_visibility == "public" do %>
                      Anyone can view your full profile
                    <% else %>
                      Only your connections can view your full profile
                    <% end %>
                  </p>
                </div>
              </label>
            </div>
          </div>

          <%!-- User Info Section --%>
          <div class="card bg-base-200 p-6">
            <h3 class="text-lg font-semibold mb-4">Account Information</h3>
            <div class="space-y-2">
              <p><span class="font-medium">Email:</span> {@user.email}</p>
              <p>
                <span class="font-medium">Member since:</span>
                {Calendar.strftime(@user.inserted_at, "%B %d, %Y")}
              </p>
            </div>
            <div class="mt-4">
              <.link navigate={~p"/users/settings"} class="btn btn-outline btn-sm">
                <.icon name="hero-cog-6-tooth" class="w-4 h-4" /> Account Settings
              </.link>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    {:ok,
     socket
     |> assign(:user, user)
     |> allow_upload(:photo,
       accept: ~w(.jpg .jpeg .png),
       max_entries: 1,
       max_file_size: 5_000_000
     )}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("toggle_visibility", _params, socket) do
    user = socket.assigns.user
    new_visibility = if user.profile_visibility == "public", do: "private", else: "public"

    case Accounts.update_user_profile(socket.assigns.current_scope, %{
           profile_visibility: new_visibility
         }) do
      {:ok, updated_user} ->
        {:noreply,
         socket
         |> assign(:user, updated_user)
         |> put_flash(:info, "Profile visibility updated to #{new_visibility}")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update profile visibility")}
    end
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :photo, ref)}
  end

  def handle_event("upload_photo", _params, socket) do
    user = socket.assigns.user
    uploads_dir = Application.get_env(:interest_spotlight, :uploads_directory)

    uploaded_files =
      consume_uploaded_entries(socket, :photo, fn %{path: path}, entry ->
        # Create user directory structure: {uploads_dir}/{user_id}/profile_photo/
        user_photo_dir = Path.join([uploads_dir, "#{user.id}", "profile_photo"])
        File.mkdir_p!(user_photo_dir)

        # Delete old photo if exists
        if user.profile_photo do
          old_path = Path.join([uploads_dir, user.profile_photo])
          File.rm(old_path)
        end

        # Use simple filename with user_id and extension
        ext = Path.extname(entry.client_name)
        filename = "#{user.id}#{ext}"
        relative_path = Path.join(["#{user.id}", "profile_photo", filename])
        dest_path = Path.join([uploads_dir, relative_path])

        # Copy file to destination
        File.cp!(path, dest_path)

        {:ok, relative_path}
      end)

    case uploaded_files do
      [relative_path | _] ->
        # Update user with new photo path (relative to uploads_dir)
        case Accounts.update_user_profile(socket.assigns.current_scope, %{
               profile_photo: relative_path
             }) do
          {:ok, updated_user} ->
            {:noreply,
             socket
             |> assign(:user, updated_user)
             |> put_flash(:info, "Photo uploaded successfully")}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to upload photo")}
        end

      [] ->
        {:noreply, socket}
    end
  end

  def handle_event("delete_photo", _params, socket) do
    user = socket.assigns.user
    uploads_dir = Application.get_env(:interest_spotlight, :uploads_directory)

    if user.profile_photo do
      # Delete file
      file_path = Path.join([uploads_dir, user.profile_photo])
      File.rm(file_path)

      # Update user
      case Accounts.update_user_profile(socket.assigns.current_scope, %{profile_photo: nil}) do
        {:ok, updated_user} ->
          {:noreply,
           socket
           |> assign(:user, updated_user)
           |> put_flash(:info, "Photo deleted successfully")}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Failed to delete photo")}
      end
    else
      {:noreply, socket}
    end
  end

  defp error_to_string(:too_large), do: "File is too large (max 5MB)"

  defp error_to_string(:not_accepted),
    do: "Invalid file type. Only JPG, JPEG, and PNG are allowed"

  defp error_to_string(:too_many_files), do: "Too many files selected"
  defp error_to_string(err), do: "Error: #{inspect(err)}"
end
