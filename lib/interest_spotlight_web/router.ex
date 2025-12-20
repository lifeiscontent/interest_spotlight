defmodule InterestSpotlightWeb.Router do
  use InterestSpotlightWeb, :router

  import InterestSpotlightWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {InterestSpotlightWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", InterestSpotlightWeb do
    pipe_through :browser

    get "/", PageController, :home
    # Serve uploaded files from external filesystem
    get "/uploads/*path", UploadController, :show
  end

  # Other scopes may use custom stacks.
  # scope "/api", InterestSpotlightWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:interest_spotlight, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: InterestSpotlightWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  # Onboarding routes (authenticated but not requiring completed onboarding)
  scope "/", InterestSpotlightWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :onboarding,
      on_mount: [{InterestSpotlightWeb.UserAuth, :require_authenticated}] do
      live "/onboarding", OnboardingLive.BasicInfo, :index
      live "/onboarding/interests", OnboardingLive.Interests, :index
      live "/onboarding/about", OnboardingLive.About, :index
    end
  end

  # Regular user routes (authenticated + onboarded + non-admin)
  scope "/", InterestSpotlightWeb do
    pipe_through [:browser, :require_authenticated_user, :require_onboarded]

    live_session :require_onboarded_user,
      on_mount: [
        {InterestSpotlightWeb.UserAuth, :require_authenticated},
        {InterestSpotlightWeb.UserAuth, :require_onboarded}
      ] do
      live "/dashboard", DashboardLive.Index, :index
      live "/profile", ProfileLive, :index
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  # Admin-only routes
  scope "/admin", InterestSpotlightWeb do
    pipe_through [:browser, :require_authenticated_user, :require_admin]

    live_session :admin,
      on_mount: [
        {InterestSpotlightWeb.UserAuth, :require_authenticated},
        {InterestSpotlightWeb.UserAuth, :require_admin}
      ] do
      live "/", AdminLive.Dashboard, :index
      live "/interests", AdminLive.Interests, :index
    end
  end

  scope "/", InterestSpotlightWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{InterestSpotlightWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
