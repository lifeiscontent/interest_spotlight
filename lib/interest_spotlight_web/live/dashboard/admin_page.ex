defmodule InterestSpotlightWeb.Dashboard.AdminPage do
  @moduledoc """
  Custom LiveDashboard page showing admin overview statistics.
  """
  use Phoenix.LiveDashboard.PageBuilder

  alias InterestSpotlight.Repo
  alias InterestSpotlight.Accounts.User
  alias InterestSpotlight.Backoffice.Admin
  alias InterestSpotlight.Interests.Interest
  alias InterestSpotlight.Interests.UserInterest

  @impl true
  def menu_link(_, _) do
    {:ok, "Admin"}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.row>
      <:col>
        <.card title="Users">
          <.fields_card fields={user_fields(@user_stats)} />
        </.card>
      </:col>
      <:col>
        <.card title="Admins">
          <.fields_card fields={admin_fields(@admin_stats)} />
        </.card>
      </:col>
      <:col>
        <.card title="Content">
          <.fields_card fields={content_fields(@content_stats)} />
        </.card>
      </:col>
    </.row>

    <.row>
      <:col>
        <.card title="Quick Links">
          <div style="padding: 1rem;">
            <ul style="list-style: none; padding: 0; margin: 0;">
              <li style="margin-bottom: 0.5rem;">
                <a href="/admins/dashboard" style="color: #3b82f6;">
                  → Admin Dashboard
                </a>
              </li>
              <li style="margin-bottom: 0.5rem;">
                <a href="/admins/interests" style="color: #3b82f6;">
                  → Manage Interests
                </a>
              </li>
              <li style="margin-bottom: 0.5rem;">
                <a href="/admins/settings" style="color: #3b82f6;">
                  → Admin Settings
                </a>
              </li>
            </ul>
          </div>
        </.card>
      </:col>
    </.row>
    """
  end

  defp user_fields(stats) do
    [
      {"Total Users", stats.total},
      {"Confirmed", stats.confirmed},
      {"Onboarded", stats.onboarded}
    ]
  end

  defp admin_fields(stats) do
    [
      {"Total Admins", stats.total},
      {"Confirmed", stats.confirmed}
    ]
  end

  defp content_fields(stats) do
    [
      {"Interests", stats.interests},
      {"User Interests", stats.user_interests}
    ]
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:user_stats, get_user_stats())
     |> assign(:admin_stats, get_admin_stats())
     |> assign(:content_stats, get_content_stats())}
  end

  @impl true
  def handle_refresh(socket) do
    {:noreply,
     socket
     |> assign(:user_stats, get_user_stats())
     |> assign(:admin_stats, get_admin_stats())
     |> assign(:content_stats, get_content_stats())}
  end

  defp get_user_stats do
    import Ecto.Query

    total = Repo.aggregate(User, :count, :id) || 0

    confirmed =
      Repo.aggregate(from(u in User, where: not is_nil(u.confirmed_at)), :count, :id) || 0

    onboarded =
      Repo.aggregate(
        from(u in User,
          where: not is_nil(u.first_name) and not is_nil(u.last_name) and not is_nil(u.location)
        ),
        :count,
        :id
      ) || 0

    %{total: total, confirmed: confirmed, onboarded: onboarded}
  end

  defp get_admin_stats do
    import Ecto.Query

    total = Repo.aggregate(Admin, :count, :id) || 0

    confirmed =
      Repo.aggregate(from(a in Admin, where: not is_nil(a.confirmed_at)), :count, :id) || 0

    %{total: total, confirmed: confirmed}
  end

  defp get_content_stats do
    interests = Repo.aggregate(Interest, :count, :id) || 0

    user_interests =
      Repo.aggregate(UserInterest, :count, :id) || 0

    %{interests: interests, user_interests: user_interests}
  end
end
