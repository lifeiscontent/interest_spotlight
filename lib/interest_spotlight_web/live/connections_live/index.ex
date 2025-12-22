defmodule InterestSpotlightWeb.ConnectionsLive.Index do
  use InterestSpotlightWeb, :live_view

  alias InterestSpotlight.Accounts
  alias InterestSpotlight.Connections
  alias InterestSpotlightWeb.Presence

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_scope.user

    # Subscribe to connection events
    if connected?(socket) do
      Connections.subscribe(current_user.id)
      track_presence(socket, current_user.id)
    end

    all_users = Accounts.list_users_except(current_user.id)
    connections = Connections.list_connections(current_user.id)
    received_requests = Connections.list_received_requests(current_user.id)
    sent_requests = Connections.list_sent_requests(current_user.id)

    # Build connection status map for all users
    connection_status_map =
      Enum.reduce(all_users, %{}, fn user, acc ->
        status = Connections.connection_status(current_user.id, user.id)
        Map.put(acc, user.id, status)
      end)

    # Get initial presence data
    presence_map = get_presence_map()

    # Get request history (accepted and rejected)
    request_history = Connections.list_request_history(current_user.id)

    {:ok,
     socket
     |> assign(:page_title, "Connections")
     |> assign(:current_tab, "all_users")
     |> assign(:all_users, all_users)
     |> assign(:connections, connections)
     |> assign(:received_requests, received_requests)
     |> assign(:sent_requests, sent_requests)
     |> assign(:request_history, request_history)
     |> assign(:connection_status_map, connection_status_map)
     |> assign(:received_count, length(received_requests))
     |> assign(:online_users, presence_map)}
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :current_tab, tab)}
  end

  @impl true
  def handle_event("send_request", %{"user_id" => user_id}, socket) do
    current_user = socket.assigns.current_scope.user
    user_id = String.to_integer(user_id)

    case Connections.create_connection_request(current_user.id, user_id) do
      {:ok, _connection} ->
        status = Connections.connection_status(current_user.id, user_id)

        {:noreply,
         socket
         |> put_flash(:info, "Connection request sent")
         |> update(:connection_status_map, &Map.put(&1, user_id, status))
         |> assign(:sent_requests, Connections.list_sent_requests(current_user.id))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to send connection request")}
    end
  end

  @impl true
  def handle_event("accept_request", %{"id" => id}, socket) do
    connection = Connections.get_connection!(id)
    current_user = socket.assigns.current_scope.user

    case Connections.accept_connection_request(connection) do
      {:ok, _connection} ->
        status = Connections.connection_status(current_user.id, connection.requester_id)

        {:noreply,
         socket
         |> put_flash(:info, "Connection accepted")
         |> assign(:connections, Connections.list_connections(current_user.id))
         |> assign(:received_requests, Connections.list_received_requests(current_user.id))
         |> assign(:request_history, Connections.list_request_history(current_user.id))
         |> update(:connection_status_map, &Map.put(&1, connection.requester_id, status))
         |> update(:received_count, &(&1 - 1))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to accept connection")}
    end
  end

  @impl true
  def handle_event("reject_request", %{"id" => id}, socket) do
    connection = Connections.get_connection!(id)
    current_user = socket.assigns.current_scope.user

    case Connections.reject_connection_request(connection) do
      {:ok, _connection} ->
        {:noreply,
         socket
         |> put_flash(:info, "Connection rejected")
         |> assign(:received_requests, Connections.list_received_requests(current_user.id))
         |> assign(:request_history, Connections.list_request_history(current_user.id))
         |> update(:connection_status_map, &Map.put(&1, connection.requester_id, nil))
         |> update(:received_count, &(&1 - 1))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to reject connection")}
    end
  end

  @impl true
  def handle_event("cancel_request", %{"id" => id}, socket) do
    connection = Connections.get_connection!(id)
    current_user = socket.assigns.current_scope.user

    case Connections.cancel_connection_request(connection) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Connection request cancelled")
         |> assign(:sent_requests, Connections.list_sent_requests(current_user.id))
         |> update(:connection_status_map, &Map.put(&1, connection.user_id, nil))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to cancel request")}
    end
  end

  @impl true
  def handle_event("remove_connection", %{"id" => id}, socket) do
    connection = Connections.get_connection!(id)
    current_user = socket.assigns.current_scope.user
    other_user_id = Connections.get_other_user(connection, current_user.id).id

    case Connections.remove_connection(connection) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Connection removed")
         |> assign(:connections, Connections.list_connections(current_user.id))
         |> update(:connection_status_map, &Map.put(&1, other_user_id, nil))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to remove connection")}
    end
  end

  @impl true
  def handle_info({:connection_request_sent, connection}, socket) do
    current_user = socket.assigns.current_scope.user

    # If we're the recipient, update received requests
    socket =
      if connection.user_id == current_user.id do
        received_requests = Connections.list_received_requests(current_user.id)

        socket
        |> assign(:received_requests, received_requests)
        |> update(:received_count, &(&1 + 1))
        |> update(
          :connection_status_map,
          &Map.put(&1, connection.requester_id, :pending_received)
        )
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:connection_accepted, connection}, socket) do
    current_user = socket.assigns.current_scope.user

    other_user_id =
      if connection.requester_id == current_user.id,
        do: connection.user_id,
        else: connection.requester_id

    {:noreply,
     socket
     |> assign(:connections, Connections.list_connections(current_user.id))
     |> assign(:received_requests, Connections.list_received_requests(current_user.id))
     |> assign(:sent_requests, Connections.list_sent_requests(current_user.id))
     |> assign(:request_history, Connections.list_request_history(current_user.id))
     |> update(:connection_status_map, &Map.put(&1, other_user_id, :connected))
     |> assign(:received_count, length(Connections.list_received_requests(current_user.id)))}
  end

  @impl true
  def handle_info({:connection_rejected, connection}, socket) do
    current_user = socket.assigns.current_scope.user

    other_user_id =
      if connection.requester_id == current_user.id,
        do: connection.user_id,
        else: connection.requester_id

    {:noreply,
     socket
     |> assign(:received_requests, Connections.list_received_requests(current_user.id))
     |> assign(:sent_requests, Connections.list_sent_requests(current_user.id))
     |> assign(:request_history, Connections.list_request_history(current_user.id))
     |> update(:connection_status_map, &Map.put(&1, other_user_id, nil))
     |> assign(:received_count, length(Connections.list_received_requests(current_user.id)))}
  end

  @impl true
  def handle_info({:connection_cancelled, connection}, socket) do
    current_user = socket.assigns.current_scope.user

    other_user_id =
      if connection.requester_id == current_user.id,
        do: connection.user_id,
        else: connection.requester_id

    {:noreply,
     socket
     |> assign(:received_requests, Connections.list_received_requests(current_user.id))
     |> assign(:sent_requests, Connections.list_sent_requests(current_user.id))
     |> update(:connection_status_map, &Map.put(&1, other_user_id, nil))
     |> assign(:received_count, length(Connections.list_received_requests(current_user.id)))}
  end

  @impl true
  def handle_info({:connection_removed, connection}, socket) do
    current_user = socket.assigns.current_scope.user

    other_user_id =
      if connection.requester_id == current_user.id,
        do: connection.user_id,
        else: connection.requester_id

    {:noreply,
     socket
     |> assign(:connections, Connections.list_connections(current_user.id))
     |> update(:connection_status_map, &Map.put(&1, other_user_id, nil))}
  end

  @impl true
  def handle_info(%{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, :online_users, get_presence_map())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-5xl mx-auto">
        <h1 class="text-3xl font-bold mb-6">Connections</h1>

        <%!-- Tabs ---%>
        <div role="tablist" class="tabs tabs-bordered mb-6">
          <a
            role="tab"
            class={["tab", @current_tab == "all_users" && "tab-active"]}
            phx-click="switch_tab"
            phx-value-tab="all_users"
          >
            Connections
          </a>
          <a
            role="tab"
            class={["tab", @current_tab == "requests" && "tab-active"]}
            phx-click="switch_tab"
            phx-value-tab="requests"
          >
            Connection Requests
            <%= if @received_count > 0 do %>
              <span class="ml-2 badge badge-primary badge-sm">{@received_count}</span>
            <% end %>
          </a>
          <a
            role="tab"
            class={["tab", @current_tab == "my_connections" && "tab-active"]}
            phx-click="switch_tab"
            phx-value-tab="my_connections"
          >
            My Connections <span class="ml-2 badge badge-ghost badge-sm">{length(@connections)}</span>
          </a>
        </div>

        <%!-- Tab Content ---%>
        <%= cond do %>
          <%!-- All Users Tab ---%>
          <% @current_tab == "all_users" -> %>
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              <%= for user <- @all_users do %>
                <div class="card bg-base-100 border border-base-300">
                  <div class="card-body p-4">
                    <div class="flex items-center gap-3 mb-3">
                      <.link navigate={~p"/connections/#{user.id}"} class="relative">
                        <%= if user.profile_photo do %>
                          <div class="avatar cursor-pointer">
                            <div class="w-12 h-12 rounded-full">
                              <img
                                src={"/uploads/#{user.profile_photo}"}
                                alt={user.first_name}
                                class="object-cover"
                              />
                            </div>
                          </div>
                        <% else %>
                          <div class="avatar placeholder cursor-pointer">
                            <div class="w-12 h-12 rounded-full bg-gradient-to-br from-primary to-secondary">
                              <span class="text-sm font-bold text-primary-content flex items-center justify-center w-full h-full">
                                {get_user_initials(user)}
                              </span>
                            </div>
                          </div>
                        <% end %>
                        <%!-- Online/Offline indicator ---%>
                        <div class={[
                          "absolute bottom-0 right-0 w-3 h-3 rounded-full border-2 border-base-100",
                          (user_online?(user.id, @online_users) && "bg-green-500") || "bg-gray-400"
                        ]}>
                        </div>
                      </.link>
                      <div class="flex-1 min-w-0">
                        <h3 class="font-semibold truncate">
                          <.link navigate={~p"/connections/#{user.id}"} class="hover:underline">
                            {user.first_name} {user.last_name}
                          </.link>
                        </h3>
                        <p class="text-sm text-base-content/70 truncate">
                          <.icon name="hero-map-pin" class="w-3 h-3 inline" /> {user.location}
                        </p>
                      </div>
                    </div>

                    <div class="card-actions">
                      <%= case Map.get(@connection_status_map, user.id) do %>
                        <% :connected -> %>
                          <.link navigate={~p"/connections/#{user.id}"} class="btn btn-sm btn-block">
                            View Profile
                          </.link>
                        <% :pending_sent -> %>
                          <button class="btn btn-sm btn-block btn-disabled" disabled>
                            Request Sent
                          </button>
                        <% :pending_received -> %>
                          <.link navigate={~p"/connections/#{user.id}"} class="btn btn-sm btn-block">
                            View Request
                          </.link>
                        <% _ -> %>
                          <button
                            phx-click="send_request"
                            phx-value-user_id={user.id}
                            class="btn btn-sm btn-primary btn-block"
                          >
                            Connect
                          </button>
                      <% end %>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
            <%!-- Connection Requests Tab ---%>
          <% @current_tab == "requests" -> %>
            <div class="space-y-4">
              <%= if @received_count > 0 do %>
                <h2 class="text-xl font-semibold mb-4">Received Requests</h2>
                <%= for request <- @received_requests do %>
                  <div class="card bg-base-100 border border-base-300">
                    <div class="card-body p-4">
                      <div class="flex items-center gap-4">
                        <div class="relative">
                          <%= if request.requester.profile_photo do %>
                            <div class="avatar">
                              <div class="w-12 h-12 rounded-full">
                                <img
                                  src={"/uploads/#{request.requester.profile_photo}"}
                                  alt={request.requester.first_name}
                                  class="object-cover"
                                />
                              </div>
                            </div>
                          <% else %>
                            <div class="avatar placeholder">
                              <div class="w-12 h-12 rounded-full bg-gradient-to-br from-primary to-secondary">
                                <span class="text-sm font-bold text-primary-content flex items-center justify-center w-full h-full">
                                  {get_user_initials(request.requester)}
                                </span>
                              </div>
                            </div>
                          <% end %>
                          <%!-- Online/Offline indicator ---%>
                          <div class={[
                            "absolute bottom-0 right-0 w-3 h-3 rounded-full border-2 border-base-100",
                            (user_online?(request.requester.id, @online_users) && "bg-green-500") ||
                              "bg-gray-400"
                          ]}>
                          </div>
                        </div>
                        <div class="flex-1">
                          <p class="font-semibold">
                            <.link
                              navigate={~p"/connections/#{request.requester.id}"}
                              class="hover:underline"
                            >
                              {request.requester.first_name} {request.requester.last_name}
                            </.link>
                          </p>
                          <p class="text-sm text-base-content/70">
                            {format_date(request.inserted_at)}
                          </p>
                        </div>
                        <div class="flex gap-2">
                          <button
                            phx-click="accept_request"
                            phx-value-id={request.id}
                            class="btn btn-sm btn-primary"
                          >
                            Accept
                          </button>
                          <button
                            phx-click="reject_request"
                            phx-value-id={request.id}
                            class="btn btn-sm btn-ghost"
                          >
                            Deny
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>
                <% end %>
              <% else %>
                <div class="text-center py-12 text-base-content/70">
                  <.icon name="hero-inbox" class="w-16 h-16 mx-auto mb-4 opacity-50" />
                  <p>No connection requests</p>
                </div>
              <% end %>

              <%= if length(@sent_requests) > 0 do %>
                <h2 class="text-xl font-semibold mb-4 mt-8">Sent Requests</h2>
                <%= for request <- @sent_requests do %>
                  <div class="card bg-base-100 border border-base-300">
                    <div class="card-body p-4">
                      <div class="flex items-center gap-4">
                        <div class="relative">
                          <%= if request.user.profile_photo do %>
                            <div class="avatar">
                              <div class="w-12 h-12 rounded-full">
                                <img
                                  src={"/uploads/#{request.user.profile_photo}"}
                                  alt={request.user.first_name}
                                  class="object-cover"
                                />
                              </div>
                            </div>
                          <% else %>
                            <div class="avatar placeholder">
                              <div class="w-12 h-12 rounded-full bg-gradient-to-br from-primary to-secondary">
                                <span class="text-sm font-bold text-primary-content flex items-center justify-center w-full h-full">
                                  {get_user_initials(request.user)}
                                </span>
                              </div>
                            </div>
                          <% end %>
                          <%!-- Online/Offline indicator ---%>
                          <div class={[
                            "absolute bottom-0 right-0 w-3 h-3 rounded-full border-2 border-base-100",
                            (user_online?(request.user.id, @online_users) && "bg-green-500") ||
                              "bg-gray-400"
                          ]}>
                          </div>
                        </div>
                        <div class="flex-1">
                          <p class="font-semibold">
                            <.link
                              navigate={~p"/connections/#{request.user.id}"}
                              class="hover:underline"
                            >
                              {request.user.first_name} {request.user.last_name}
                            </.link>
                          </p>
                          <p class="text-sm text-base-content/70">Pending</p>
                        </div>
                        <button
                          phx-click="cancel_request"
                          phx-value-id={request.id}
                          class="btn btn-sm btn-ghost"
                        >
                          Cancel
                        </button>
                      </div>
                    </div>
                  </div>
                <% end %>
              <% end %>

              <%= if length(@request_history) > 0 do %>
                <h2 class="text-xl font-semibold mb-4 mt-8">Request History</h2>
                <%= for request <- @request_history do %>
                  <div class="card bg-base-100 border border-base-300">
                    <div class="card-body p-4">
                      <div class="flex items-center gap-4">
                        <.link navigate={~p"/connections/#{request.requester.id}"} class="relative">
                          <%= if request.requester.profile_photo do %>
                            <div class="avatar cursor-pointer">
                              <div class="w-12 h-12 rounded-full">
                                <img
                                  src={"/uploads/#{request.requester.profile_photo}"}
                                  alt={request.requester.first_name}
                                  class="object-cover"
                                />
                              </div>
                            </div>
                          <% else %>
                            <div class="avatar placeholder cursor-pointer">
                              <div class="w-12 h-12 rounded-full bg-gradient-to-br from-primary to-secondary">
                                <span class="text-sm font-bold text-primary-content flex items-center justify-center w-full h-full">
                                  {get_user_initials(request.requester)}
                                </span>
                              </div>
                            </div>
                          <% end %>
                          <%!-- Online/Offline indicator ---%>
                          <div class={[
                            "absolute bottom-0 right-0 w-3 h-3 rounded-full border-2 border-base-100",
                            (user_online?(request.requester.id, @online_users) && "bg-green-500") ||
                              "bg-gray-400"
                          ]}>
                          </div>
                        </.link>
                        <div class="flex-1">
                          <p class="font-semibold">
                            <.link
                              navigate={~p"/connections/#{request.requester.id}"}
                              class="hover:underline"
                            >
                              {request.requester.first_name} {request.requester.last_name}
                            </.link>
                          </p>
                          <p class="text-sm text-base-content/70">
                            {format_date(request.updated_at)}
                          </p>
                        </div>
                        <div class="flex items-center gap-2">
                          <%= if request.status == "accepted" do %>
                            <.icon name="hero-user" class="w-4 h-4 text-base-content/70" />
                            <span class="text-sm text-base-content/70">
                              You have accepted the request
                            </span>
                          <% else %>
                            <.icon name="hero-x-mark" class="w-4 h-4 text-red-500" />
                            <span class="text-sm text-red-500">You have declined the request</span>
                          <% end %>
                        </div>
                      </div>
                    </div>
                  </div>
                <% end %>
              <% end %>
            </div>
            <%!-- My Connections Tab ---%>
          <% @current_tab == "my_connections" -> %>
            <%= if length(@connections) > 0 do %>
              <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                <%= for connection <- @connections do %>
                  <% other_user =
                    Connections.get_other_user(connection, @current_scope.user.id) %>
                  <div class="card bg-base-100 border border-base-300">
                    <div class="card-body p-4">
                      <div class="flex items-center gap-3 mb-3">
                        <.link navigate={~p"/connections/#{other_user.id}"} class="relative">
                          <%= if other_user.profile_photo do %>
                            <div class="avatar cursor-pointer">
                              <div class="w-12 h-12 rounded-full">
                                <img
                                  src={"/uploads/#{other_user.profile_photo}"}
                                  alt={other_user.first_name}
                                  class="object-cover"
                                />
                              </div>
                            </div>
                          <% else %>
                            <div class="avatar placeholder cursor-pointer">
                              <div class="w-12 h-12 rounded-full bg-gradient-to-br from-primary to-secondary">
                                <span class="text-sm font-bold text-primary-content flex items-center justify-center w-full h-full">
                                  {get_user_initials(other_user)}
                                </span>
                              </div>
                            </div>
                          <% end %>
                          <%!-- Online/Offline indicator ---%>
                          <div class={[
                            "absolute bottom-0 right-0 w-3 h-3 rounded-full border-2 border-base-100",
                            (user_online?(other_user.id, @online_users) && "bg-green-500") ||
                              "bg-gray-400"
                          ]}>
                          </div>
                        </.link>
                        <div class="flex-1 min-w-0">
                          <h3 class="font-semibold truncate">
                            <.link
                              navigate={~p"/connections/#{other_user.id}"}
                              class="hover:underline"
                            >
                              {other_user.first_name} {other_user.last_name}
                            </.link>
                          </h3>
                          <p class="text-sm text-base-content/70 truncate">
                            <.icon name="hero-map-pin" class="w-3 h-3 inline" /> {other_user.location}
                          </p>
                        </div>
                        <button
                          phx-click="remove_connection"
                          phx-value-id={connection.id}
                          class="btn btn-ghost btn-sm btn-circle"
                          title="Remove connection"
                        >
                          <.icon name="hero-x-mark" class="w-5 h-5" />
                        </button>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>
            <% else %>
              <div class="text-center py-12 text-base-content/70">
                <.icon name="hero-user-group" class="w-16 h-16 mx-auto mb-4 opacity-50" />
                <p>No connections yet</p>
                <button
                  phx-click="switch_tab"
                  phx-value-tab="all_users"
                  class="btn btn-primary btn-sm mt-4"
                >
                  Find People to Connect
                </button>
              </div>
            <% end %>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  defp format_date(naive_datetime) do
    date = NaiveDateTime.to_date(naive_datetime)
    today = Date.utc_today()
    days_ago = Date.diff(today, date)

    cond do
      days_ago == 0 -> "Today"
      days_ago == 1 -> "Yesterday"
      days_ago < 7 -> "#{days_ago} days ago"
      true -> Date.to_string(date)
    end
  end

  defp track_presence(_socket, user_id) do
    try do
      Presence.track(self(), "online_users", user_id, %{
        online_at: System.system_time(:second)
      })
    rescue
      ArgumentError -> :ok
    end
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
