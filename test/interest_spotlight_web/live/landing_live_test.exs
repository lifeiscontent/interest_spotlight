defmodule InterestSpotlightWeb.LandingLiveTest do
  use InterestSpotlightWeb.ConnCase

  import Phoenix.LiveViewTest

  test "GET /", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/")
    assert html =~ "Interest Spotlight"
    assert html =~ "Join now"
  end
end
