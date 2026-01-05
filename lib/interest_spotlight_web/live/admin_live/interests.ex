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
     |> assign(:edit_name, "")
     |> assign(:edit_slug, "")}
  end

  def render(assigns) do
    ~H"""
    <Layouts.admin_app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-2xl mx-auto">
        <div class="flex items-center justify-between mb-6">
          <h1 class="text-2xl font-bold">Manage Interests</h1>
          <.link navigate={~p"/admins/dashboard"} class="text-primary hover:underline">
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
              class="input input-bordered flex-1"
              phx-change="update_new_interest"
            />
            <button type="submit" class="btn btn-primary">
              Add
            </button>
          </div>
        </form>

        <div class="space-y-2">
          <%= for interest <- @interests do %>
            <div class="flex items-center justify-between p-3 bg-base-100 border border-base-300 rounded-lg">
              <%= if @editing_id == interest.id do %>
                <form phx-submit="save_edit" class="flex-1">
                  <div class="flex flex-col gap-2">
                    <div class="flex gap-2 items-center">
                      <label class="text-sm text-base-content/70 w-12">Name</label>
                      <input
                        type="text"
                        name="name"
                        value={@edit_name}
                        class="input input-bordered input-sm flex-1"
                        phx-change="update_edit_fields"
                        autofocus
                      />
                    </div>
                    <div class="flex gap-2 items-center">
                      <label class="text-sm text-base-content/70 w-12">Slug</label>
                      <input
                        type="text"
                        name="slug"
                        value={@edit_slug}
                        class="input input-bordered input-sm flex-1 font-mono text-sm"
                        phx-change="update_edit_fields"
                        placeholder="auto-generated from name"
                      />
                    </div>
                    <div class="flex gap-2 justify-end">
                      <button type="button" phx-click="cancel_edit" class="btn btn-ghost btn-sm">
                        Cancel
                      </button>
                      <button type="submit" class="btn btn-success btn-sm">
                        Save
                      </button>
                    </div>
                  </div>
                </form>
              <% else %>
                <div class="flex-1">
                  <span class="font-medium">{interest.name}</span>
                  <span class="text-base-content/50 text-sm ml-2">/{interest.slug}</span>
                </div>
                <div class="flex gap-2">
                  <button
                    phx-click="start_edit"
                    phx-value-id={interest.id}
                    phx-value-name={interest.name}
                    phx-value-slug={interest.slug}
                    class="btn btn-ghost btn-sm text-primary"
                  >
                    Edit
                  </button>
                  <button
                    phx-click="delete"
                    phx-value-id={interest.id}
                    data-confirm="Are you sure you want to delete this interest?"
                    class="btn btn-ghost btn-sm text-error"
                  >
                    Delete
                  </button>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>

        <%= if Enum.empty?(@interests) do %>
          <p class="text-center text-base-content/50 py-8">No interests yet. Add one above.</p>
        <% end %>
      </div>
    </Layouts.admin_app>
    """
  end

  def handle_event("update_new_interest", %{"name" => name}, socket) do
    {:noreply, assign(socket, :new_interest, name)}
  end

  def handle_event("add_interest", %{"name" => name}, socket) do
    name
    |> String.trim()
    |> do_add_interest(socket)
  end

  defp do_add_interest("", socket), do: {:noreply, socket}

  defp do_add_interest(name, socket) do
    case Interests.create_interest(%{name: name}) do
      {:ok, _interest} ->
        {:noreply,
         socket
         |> assign(:interests, Interests.list_interests())
         |> assign(:new_interest, "")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not create interest. It may already exist.")}
    end
  end

  def handle_event("start_edit", %{"id" => id, "name" => name, "slug" => slug}, socket) do
    {:noreply,
     socket
     |> assign(:editing_id, String.to_integer(id))
     |> assign(:edit_name, name)
     |> assign(:edit_slug, slug)}
  end

  def handle_event("update_edit_fields", params, socket) do
    socket =
      socket
      |> maybe_assign(:edit_name, params["name"])
      |> maybe_assign(:edit_slug, params["slug"])

    {:noreply, socket}
  end

  defp maybe_assign(socket, _key, nil), do: socket
  defp maybe_assign(socket, key, value), do: assign(socket, key, value)

  def handle_event("save_edit", %{"name" => name, "slug" => slug}, socket) do
    name = String.trim(name)
    slug = String.trim(slug)
    do_save_edit(name, slug, socket)
  end

  defp do_save_edit("", _slug, socket), do: {:noreply, socket}

  defp do_save_edit(name, slug, socket) do
    interest = Interests.get_interest!(socket.assigns.editing_id)

    attrs =
      case slug do
        "" -> %{name: name}
        _ -> %{name: name, slug: slug}
      end

    case Interests.update_interest(interest, attrs) do
      {:ok, _interest} ->
        {:noreply,
         socket
         |> assign(:interests, Interests.list_interests())
         |> assign(:editing_id, nil)
         |> assign(:edit_name, "")
         |> assign(:edit_slug, "")}

      {:error, changeset} ->
        errors = format_errors(changeset)
        {:noreply, put_flash(socket, :error, "Could not update interest. #{errors}")}
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, msgs} -> "#{field} #{Enum.join(msgs, ", ")}" end)
    |> Enum.join("; ")
  end

  def handle_event("cancel_edit", _params, socket) do
    {:noreply,
     socket
     |> assign(:editing_id, nil)
     |> assign(:edit_name, "")
     |> assign(:edit_slug, "")}
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
