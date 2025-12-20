defmodule InterestSpotlightWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use InterestSpotlightWeb, :html

  alias Phoenix.LiveView.JS

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders the authenticated app layout with fixed header, scrollable content, and fixed footer.

  Mobile: Bottom navigation bar
  Desktop: Sidebar navigation

  ## Examples

      <Layouts.app flash={@flash} current_scope={@current_scope}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="flex flex-col h-screen md:flex-row">
      <%!-- Desktop Sidebar - hidden on mobile --%>
      <aside class="hidden md:flex md:flex-col md:w-64 md:border-r md:border-base-300 md:bg-base-100">
        <div class="p-4 border-b border-base-300">
          <.link navigate={~p"/dashboard"} class="text-xl font-bold text-primary">
            INTERESTSPOTLIGHT
          </.link>
        </div>
        <nav class="flex-1 p-4">
          <ul class="menu space-y-1">
            <li>
              <.link navigate={~p"/dashboard"} class="flex items-center gap-3">
                <.icon name="hero-home" class="size-5" />
                <span>Home</span>
              </.link>
            </li>
            <li>
              <.link href="#" class="flex items-center gap-3">
                <.icon name="hero-calendar" class="size-5" />
                <span>Calendar</span>
              </.link>
            </li>
            <li>
              <.link href="#" class="flex items-center gap-3">
                <.icon name="hero-user-group" class="size-5" />
                <span>Connections</span>
              </.link>
            </li>
            <li>
              <.link navigate={~p"/profile"} class="flex items-center gap-3">
                <.icon name="hero-user-circle" class="size-5" />
                <span>Profile</span>
              </.link>
            </li>
          </ul>
        </nav>
        <div class="p-4 border-t border-base-300">
          <.theme_toggle />
        </div>
      </aside>

      <%!-- Main content area --%>
      <div class="flex-1 flex flex-col min-h-0">
        <%!-- Fixed Header --%>
        <header class="sticky top-0 z-10 bg-base-100 border-b border-base-300">
          <div class="flex items-center justify-between px-4 h-14">
            <%!-- Logo - visible on mobile, hidden on desktop --%>
            <.link navigate={~p"/dashboard"} class="text-lg font-bold text-primary md:hidden">
              INTERESTSPOTLIGHT
            </.link>
            <%!-- Spacer for desktop --%>
            <div class="hidden md:block"></div>

            <%!-- User dropdown --%>
            <div class="dropdown dropdown-end">
              <div tabindex="0" role="button" class="btn btn-ghost btn-circle avatar">
                <.icon name="hero-user-circle" class="size-8" />
              </div>
              <ul
                tabindex="0"
                class="dropdown-content menu bg-base-100 rounded-box z-[1] w-52 p-2 shadow border border-base-300"
              >
                <li class="menu-title px-2 py-1 text-xs opacity-70">
                  {@current_scope && @current_scope.user && @current_scope.user.email}
                </li>
                <li>
                  <.link navigate={~p"/users/settings"}>
                    <.icon name="hero-cog-6-tooth" class="size-4" /> Settings
                  </.link>
                </li>
                <li>
                  <div class="flex items-center justify-between">
                    <span class="flex items-center gap-2">
                      <.icon name="hero-sun" class="size-4" /> Theme
                    </span>
                    <.theme_toggle />
                  </div>
                </li>
                <div class="divider my-1"></div>
                <li>
                  <.link href={~p"/users/log-out"} method="delete" class="text-error">
                    <.icon name="hero-arrow-right-on-rectangle" class="size-4" /> Log out
                  </.link>
                </li>
              </ul>
            </div>
          </div>
        </header>

        <%!-- Scrollable Content --%>
        <main class="flex-1 overflow-y-auto pb-16 md:pb-0">
          <div class="p-4">
            {render_slot(@inner_block)}
          </div>
        </main>

        <%!-- Fixed Bottom Navigation - mobile only --%>
        <nav class="fixed bottom-0 left-0 right-0 bg-base-100 border-t border-base-300 md:hidden z-10">
          <div class="flex items-center justify-around h-16">
            <.bottom_nav_item href={~p"/dashboard"} icon="hero-home" label="Home" />
            <.bottom_nav_item href="#" icon="hero-calendar" label="Calendar" />
            <.bottom_nav_item href="#" icon="hero-user-group" label="Connections" badge={4} />
            <.bottom_nav_item href={~p"/profile"} icon="hero-user-circle" label="Profile" />
          </div>
        </nav>
      </div>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  attr :href, :string, required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :badge, :integer, default: nil
  attr :active, :boolean, default: false

  defp bottom_nav_item(assigns) do
    ~H"""
    <.link navigate={@href} class="flex flex-col items-center justify-center w-16 py-1 group">
      <div class="relative">
        <.icon name={@icon} class="size-6 text-base-content/70 group-hover:text-primary" />
        <span
          :if={@badge}
          class="absolute -top-1 -right-2 bg-primary text-primary-content text-xs rounded-full size-4 flex items-center justify-center"
        >
          {@badge}
        </span>
      </div>
      <span class="text-xs mt-1 text-base-content/70 group-hover:text-primary">{@label}</span>
    </.link>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
