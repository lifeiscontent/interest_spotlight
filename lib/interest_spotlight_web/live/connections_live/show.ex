defmodule InterestSpotlightWeb.ConnectionsLive.Show do
  use InterestSpotlightWeb, :live_view

  alias InterestSpotlight.Accounts
  alias InterestSpotlight.Accounts.User
  alias InterestSpotlight.Connections
  alias InterestSpotlight.Interests
  alias InterestSpotlight.Profiles
  alias InterestSpotlightWeb.Presence

  @impl true
  def mount(%{"id" => user_id}, _session, socket) do
    current_user = socket.assigns.current_scope.user

    # Don't allow viewing your own profile here
    if to_string(current_user.id) == user_id do
      {:ok,
       socket
       |> put_flash(:error, "Cannot view your own profile here")
       |> push_navigate(to: ~p"/profile")}
    else
      # Subscribe to connection events
      if connected?(socket) do
        Connections.subscribe(current_user.id)
      end

      user = Accounts.get_user!(user_id)
      profile = Profiles.get_profile_by_user_id(user.id)
      interests = Interests.list_user_interests(user.id)
      connection_status = Connections.connection_status(current_user.id, user.id)
      connection = Connections.get_connection_between(current_user.id, user.id)

      # Get presence data
      presence_map = get_presence_map()

      # Determine if the current user can view the full profile
      # Full profile is visible if: user's profile is public OR users are connected
      can_view_profile = User.public_profile?(user) || connection_status == :connected

      {:ok,
       socket
       |> assign(:page_title, "#{user.first_name} #{user.last_name}")
       |> assign(:user, user)
       |> assign(:profile, profile)
       |> assign(:interests, interests)
       |> assign(:connection_status, connection_status)
       |> assign(:connection, connection)
       |> assign(:online_users, presence_map)
       |> assign(:can_view_profile, can_view_profile)}
    end
  end

  @impl true
  def handle_event("send_connection_request", _params, socket) do
    current_user = socket.assigns.current_scope.user
    user = socket.assigns.user

    case Connections.create_connection_request(current_user.id, user.id) do
      {:ok, connection} ->
        {:noreply,
         socket
         |> put_flash(:info, "Connection request sent")
         |> assign(:connection_status, :pending_sent)
         |> assign(:connection, connection)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to send connection request")}
    end
  end

  @impl true
  def handle_event("cancel_connection_request", _params, socket) do
    connection = socket.assigns.connection

    case Connections.cancel_connection_request(connection) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Connection request cancelled")
         |> assign(:connection_status, nil)
         |> assign(:connection, nil)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to cancel request")}
    end
  end

  @impl true
  def handle_event("accept_connection_request", _params, socket) do
    connection = socket.assigns.connection

    case Connections.accept_connection_request(connection) do
      {:ok, updated_connection} ->
        {:noreply,
         socket
         |> put_flash(:info, "Connection accepted")
         |> assign(:connection_status, :connected)
         |> assign(:connection, updated_connection)
         |> assign(:can_view_profile, true)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to accept connection")}
    end
  end

  @impl true
  def handle_event("reject_connection_request", _params, socket) do
    connection = socket.assigns.connection

    case Connections.reject_connection_request(connection) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Connection rejected")
         |> assign(:connection_status, nil)
         |> assign(:connection, nil)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to reject connection")}
    end
  end

  @impl true
  def handle_event("remove_connection", _params, socket) do
    connection = socket.assigns.connection

    case Connections.remove_connection(connection) do
      {:ok, _} ->
        # Reload user to get latest profile_visibility and recalculate can_view_profile
        user = Accounts.get_user!(socket.assigns.user.id)
        can_view_profile = User.public_profile?(user)

        {:noreply,
         socket
         |> put_flash(:info, "Connection removed")
         |> assign(:user, user)
         |> assign(:connection_status, nil)
         |> assign(:connection, nil)
         |> assign(:can_view_profile, can_view_profile)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to remove connection")}
    end
  end

  @impl true
  def handle_info({:connection_request_sent, connection}, socket) do
    current_user = socket.assigns.current_scope.user
    user = socket.assigns.user

    # Update if this affects the current view
    if connection.requester_id == user.id && connection.user_id == current_user.id do
      {:noreply,
       socket
       |> assign(:connection_status, :pending_received)
       |> assign(:connection, connection)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:connection_accepted, connection}, socket) do
    current_user = socket.assigns.current_scope.user
    user = socket.assigns.user

    # Update if this affects the current view
    if (connection.requester_id == current_user.id && connection.user_id == user.id) ||
         (connection.requester_id == user.id && connection.user_id == current_user.id) do
      # Reload interests since they're now visible
      interests = Interests.list_user_interests(user.id)
      profile = Profiles.get_profile_by_user_id(user.id)

      {:noreply,
       socket
       |> assign(:connection_status, :connected)
       |> assign(:connection, connection)
       |> assign(:interests, interests)
       |> assign(:profile, profile)
       |> assign(:can_view_profile, true)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:connection_rejected, _connection}, socket) do
    {:noreply,
     socket
     |> assign(:connection_status, nil)
     |> assign(:connection, nil)}
  end

  @impl true
  def handle_info({:connection_cancelled, _connection}, socket) do
    {:noreply,
     socket
     |> assign(:connection_status, nil)
     |> assign(:connection, nil)}
  end

  @impl true
  def handle_info({:connection_removed, _connection}, socket) do
    # Reload user to get latest profile_visibility
    user = Accounts.get_user!(socket.assigns.user.id)
    # Recalculate can_view_profile since connection is removed
    can_view_profile = User.public_profile?(user)

    {:noreply,
     socket
     |> assign(:user, user)
     |> assign(:connection_status, nil)
     |> assign(:connection, nil)
     |> assign(:can_view_profile, can_view_profile)}
  end

  @impl true
  def handle_info(%{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, :online_users, get_presence_map())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-4xl mx-auto px-4 py-8">
        <%!-- Profile Header ---%>
        <div class="bg-white rounded-lg shadow-md p-8 mb-6">
          <div class="flex items-start gap-6">
            <div class="relative flex-shrink-0">
              <%= if @user.profile_photo do %>
                <img
                  src={"/uploads/#{@user.profile_photo}"}
                  alt={@user.first_name}
                  class="w-24 h-24 rounded-full object-cover"
                />
              <% else %>
                <div class="w-24 h-24 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full">
                  <span class="text-3xl font-bold text-white flex items-center justify-center w-full h-full">
                    {get_user_initials(@user)}
                  </span>
                </div>
              <% end %>
              <%!-- Online/Offline indicator ---%>
              <div class={[
                "absolute bottom-1 right-1 w-5 h-5 rounded-full border-4 border-white",
                (user_online?(@user.id, @online_users) && "bg-green-500") || "bg-gray-400"
              ]}>
              </div>
            </div>

            <div class="flex-1">
              <h1 class="text-3xl font-bold mb-2">
                {@user.first_name} {@user.last_name}
              </h1>
              <p class="text-gray-600 mb-4">
                <.icon name="hero-map-pin" class="w-4 h-4 inline" /> {@user.location}
              </p>

              <%!-- Connection Action Buttons ---%>
              <div class="flex gap-3">
                <%= cond do %>
                  <% @connection_status == :connected -> %>
                    <button
                      phx-click="remove_connection"
                      class="px-6 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300"
                    >
                      Remove Connection
                    </button>
                  <% @connection_status == :pending_sent -> %>
                    <button
                      phx-click="cancel_connection_request"
                      class="px-6 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300"
                    >
                      Cancel Request
                    </button>
                  <% @connection_status == :pending_received -> %>
                    <button
                      phx-click="accept_connection_request"
                      class="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                    >
                      Accept Request
                    </button>
                    <button
                      phx-click="reject_connection_request"
                      class="px-6 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300"
                    >
                      Reject
                    </button>
                  <% true -> %>
                    <button
                      phx-click="send_connection_request"
                      class="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                    >
                      Connect
                    </button>
                <% end %>
              </div>
            </div>
          </div>
        </div>

        <%!-- Content Sections ---%>
        <%= if @can_view_profile do %>
          <%!-- Interests Section ---%>
          <%= if length(@interests) > 0 do %>
            <div class="bg-white rounded-lg shadow-md p-6 mb-6">
              <h2 class="text-xl font-semibold mb-4">Interests</h2>
              <div class="flex flex-wrap gap-2">
                <%= for user_interest <- @interests do %>
                  <span class="px-3 py-1 bg-blue-100 text-blue-800 rounded-full text-sm">
                    {user_interest.interest.name}
                  </span>
                <% end %>
              </div>
            </div>
          <% end %>
          <%!-- Bio Section ---%>
          <%= if @profile && @profile.bio do %>
            <div class="bg-white rounded-lg shadow-md p-6 mb-6">
              <h2 class="text-xl font-semibold mb-4">About</h2>
              <p class="text-gray-700 whitespace-pre-wrap">{@profile.bio}</p>
            </div>
          <% end %>
          <%!-- Social Links Section ---%>
          <%= if @profile && has_social_links?(@profile) do %>
            <div class="bg-white rounded-lg shadow-md p-6">
              <h2 class="text-xl font-semibold mb-4">Social Links</h2>
              <div class="space-y-2">
                <%= if @profile.instagram do %>
                  <p>
                    <.icon name="hero-camera" class="w-5 h-5 inline" /> Instagram:
                    <a
                      href={"https://instagram.com/#{@profile.instagram}"}
                      target="_blank"
                      class="text-blue-600 hover:underline"
                    >
                      @{@profile.instagram}
                    </a>
                  </p>
                <% end %>
                <%= if @profile.facebook do %>
                  <p>
                    <.icon name="hero-user-circle" class="w-5 h-5 inline" /> Facebook:
                    <a
                      href={"https://facebook.com/#{@profile.facebook}"}
                      target="_blank"
                      class="text-blue-600 hover:underline"
                    >
                      {@profile.facebook}
                    </a>
                  </p>
                <% end %>
                <%= if @profile.twitter do %>
                  <p>
                    <.icon name="hero-at-symbol" class="w-5 h-5 inline" /> Twitter:
                    <a
                      href={"https://twitter.com/#{@profile.twitter}"}
                      target="_blank"
                      class="text-blue-600 hover:underline"
                    >
                      @{@profile.twitter}
                    </a>
                  </p>
                <% end %>
                <%= if @profile.tiktok do %>
                  <p>
                    <.icon name="hero-musical-note" class="w-5 h-5 inline" /> TikTok:
                    <a
                      href={"https://tiktok.com/@#{@profile.tiktok}"}
                      target="_blank"
                      class="text-blue-600 hover:underline"
                    >
                      @{@profile.tiktok}
                    </a>
                  </p>
                <% end %>
                <%= if @profile.youtube do %>
                  <p>
                    <.icon name="hero-play" class="w-5 h-5 inline" /> YouTube:
                    <a
                      href={"https://youtube.com/@#{@profile.youtube}"}
                      target="_blank"
                      class="text-blue-600 hover:underline"
                    >
                      @{@profile.youtube}
                    </a>
                  </p>
                <% end %>
              </div>
            </div>
          <% end %>
        <% else %>
          <%!-- Show limited profile if profile is private and not connected ---%>
          <div class="bg-gray-50 rounded-lg p-8 text-center">
            <.icon name="hero-lock-closed" class="w-16 h-16 mx-auto text-gray-400 mb-4" />
            <h3 class="text-xl font-semibold text-gray-700 mb-2">
              This profile is private
            </h3>
            <p class="text-gray-600">
              Connect with {@user.first_name} to view their full profile
            </p>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  defp has_social_links?(profile) do
    profile.instagram || profile.facebook || profile.twitter || profile.tiktok ||
      profile.youtube
  end

  defp get_presence_map do
    try do
      Presence.list("online_users")
      |> Enum.map(fn {user_id, _} -> String.to_integer(user_id) end)
      |> MapSet.new()
    rescue
      ArgumentError -> MapSet.new()
    end
  end

  defp user_online?(user_id, online_users) do
    MapSet.member?(online_users, user_id)
  end

  defp get_user_initials(user) do
    cond do
      user.first_name && user.last_name ->
        String.upcase("#{String.first(user.first_name)}#{String.first(user.last_name)}")

      user.first_name ->
        String.upcase(String.slice(user.first_name, 0..1))

      user.email ->
        String.upcase(String.first(user.email))

      true ->
        "?"
    end
  end
end
