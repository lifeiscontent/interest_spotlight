defmodule InterestSpotlightWeb.PageController do
  use InterestSpotlightWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
