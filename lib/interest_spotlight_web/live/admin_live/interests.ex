defmodule InterestSpotlightWeb.AdminLive.Interests do
  use InterestSpotlightWeb, :live_view

  alias InterestSpotlight.Interests

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Manage Interests")
     |> assign(:interests, Interests.list_interests())
     |> assign(:editing_id, nil)
     |> assign(:new_interest, "")
     |> assign(:edit_name, "")}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto p-4">
      <div class="flex items-center justify-between mb-6">
        <h1 class="text-2xl font-bold">Manage Interests</h1>
        <.link navigate={~p"/admin"} class="text-blue-600 hover:underline">
          ← Back to Dashboard
        </.link>
      </div>

      <form phx-submit="add_interest" class="mb-6">
        <div class="flex gap-2">
          <input
            type="text"
            name="name"
            value={@new_interest}
            placeholder="New interest name"
            class="flex-1 border border-gray-300 rounded-lg px-4 py-2"
            phx-change="update_new_interest"
          />
          <button
            type="submit"
            class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          >
            Add
          </button>
        </div>
      </form>

      <div class="space-y-2">
        <%= for interest <- @interests do %>
          <div class="flex items-center justify-between p-3 bg-white border border-gray-200 rounded-lg">
            <%= if @editing_id == interest.id do %>
              <form phx-submit="save_edit" class="flex-1 flex gap-2">
                <input
                  type="text"
                  name="name"
                  value={@edit_name}
                  class="flex-1 border border-gray-300 rounded px-3 py-1"
                  phx-change="update_edit_name"
                  autofocus
                />
                <button type="submit" class="px-3 py-1 bg-green-600 text-white rounded text-sm">
                  Save
                </button>
                <button
                  type="button"
                  phx-click="cancel_edit"
                  class="px-3 py-1 bg-gray-300 text-gray-700 rounded text-sm"
                >
                  Cancel
                </button>
              </form>
            <% else %>
              <span>{interest.name}</span>
              <div class="flex gap-2">
                <button
                  phx-click="start_edit"
                  phx-value-id={interest.id}
                  phx-value-name={interest.name}
                  class="px-3 py-1 text-blue-600 hover:bg-blue-50 rounded text-sm"
                >
                  Edit
                </button>
                <button
                  phx-click="delete"
                  phx-value-id={interest.id}
                  data-confirm="Are you sure you want to delete this interest?"
                  class="px-3 py-1 text-red-600 hover:bg-red-50 rounded text-sm"
                >
                  Delete
                </button>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>

      <%= if Enum.empty?(@interests) do %>
        <p class="text-center text-gray-500 py-8">No interests yet. Add one above.</p>
      <% end %>
    </div>
    """
  end

  def handle_event("update_new_interest", %{"name" => name}, socket) do
    {:noreply, assign(socket, :new_interest, name)}
  end

  def handle_event("add_interest", %{"name" => name}, socket) do
    name = String.trim(name)

    if name != "" do
      case Interests.create_interest(%{name: name}) do
        {:ok, _interest} ->
          {:noreply,
           socket
           |> assign(:interests, Interests.list_interests())
           |> assign(:new_interest, "")}

        {:error, _changeset} ->
          {:noreply,
           put_flash(socket, :error, "Could not create interest. It may already exist.")}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("start_edit", %{"id" => id, "name" => name}, socket) do
    {:noreply,
     socket
     |> assign(:editing_id, String.to_integer(id))
     |> assign(:edit_name, name)}
  end

  def handle_event("update_edit_name", %{"name" => name}, socket) do
    {:noreply, assign(socket, :edit_name, name)}
  end

  def handle_event("save_edit", %{"name" => name}, socket) do
    name = String.trim(name)

    if name != "" do
      interest = Interests.get_interest!(socket.assigns.editing_id)

      case Interests.update_interest(interest, %{name: name}) do
        {:ok, _interest} ->
          {:noreply,
           socket
           |> assign(:interests, Interests.list_interests())
           |> assign(:editing_id, nil)
           |> assign(:edit_name, "")}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Could not update interest.")}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("cancel_edit", _params, socket) do
    {:noreply,
     socket
     |> assign(:editing_id, nil)
     |> assign(:edit_name, "")}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    interest = Interests.get_interest!(String.to_integer(id))

    case Interests.delete_interest(interest) do
      {:ok, _interest} ->
        {:noreply, assign(socket, :interests, Interests.list_interests())}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not delete interest.")}
    end
  end
end
