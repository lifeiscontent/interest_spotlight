defmodule InterestSpotlightWeb.Dashboard.InterestsPage do
  @moduledoc """
  Custom LiveDashboard page showing interests overview with live table.
  """
  use Phoenix.LiveDashboard.PageBuilder

  alias InterestSpotlight.Repo
  alias InterestSpotlight.Interests.Interest
  alias InterestSpotlight.Interests.UserInterest

  import Ecto.Query

  @impl true
  def menu_link(_, _) do
    {:ok, "Interests"}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_table
      id="interests-table"
      dom_id="interests-table"
      page={@page}
      title="Interests"
      row_fetcher={&fetch_interests/2}
      rows_name="interests"
    >
      <:col field={:id} header="ID" sortable={:asc} />
      <:col field={:name} header="Name" sortable={:asc} />
      <:col field={:slug} header="Slug" />
      <:col field={:user_count} header="Users" text_align="right" sortable={:desc} />
      <:col :let={interest} field={:inserted_at} header="Created">
        {format_datetime(interest[:inserted_at])}
      </:col>
    </.live_table>
    """
  end

  defp fetch_interests(params, _node) do
    %{search: search, sort_by: sort_by, sort_dir: sort_dir, limit: limit} = params

    query =
      from(i in Interest,
        left_join: ui in UserInterest,
        on: ui.interest_id == i.id,
        group_by: i.id,
        select: %{
          id: i.id,
          name: i.name,
          slug: i.slug,
          inserted_at: i.inserted_at,
          user_count: count(ui.id)
        }
      )

    query =
      if search && search != "" do
        search_term = "%#{search}%"
        where(query, [i], ilike(i.name, ^search_term) or ilike(i.slug, ^search_term))
      else
        query
      end

    query =
      case sort_by do
        :id -> order_by(query, [i], [{^sort_dir, i.id}])
        :name -> order_by(query, [i], [{^sort_dir, i.name}])
        :user_count -> order_by(query, [i, ui], [{^sort_dir, count(ui.id)}])
        _ -> order_by(query, [i], [{^sort_dir, i.id}])
      end

    total = Repo.aggregate(Interest, :count, :id)
    interests = Repo.all(limit(query, ^limit))

    {interests, total}
  end

  defp format_datetime(nil), do: "-"

  defp format_datetime(datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M")
  end
end
