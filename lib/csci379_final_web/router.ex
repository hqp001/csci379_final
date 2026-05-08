defmodule Csci379FinalWeb.Router do
  use Csci379FinalWeb, :router

  import Csci379FinalWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {Csci379FinalWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
    plug Csci379FinalWeb.LocalePlug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Csci379FinalWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/set-locale", LocaleController, :set
  end

  # Other scopes may use custom stacks.
  # scope "/api", Csci379FinalWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:csci379_final, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: Csci379FinalWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/auth", Csci379FinalWeb do
    pipe_through :browser

    get "/:provider", OAuthController, :request
    get "/:provider/callback", OAuthController, :callback
  end

  scope "/", Csci379FinalWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
  end

  scope "/", Csci379FinalWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm-email/:token", UserSettingsController, :confirm_email
  end

  live_session :authenticated,
    on_mount: [{Csci379FinalWeb.UserAuth, :require_authenticated_user}] do
    scope "/", Csci379FinalWeb do
      pipe_through [:browser, :require_authenticated_user]

      live "/dashboard", DashboardLive, :index
      live "/stories/new", StoryLive.New, :new
      live "/stories/:id", StoryLive.Show, :show
      live "/stories/:story_id/scenes/:id", SceneLive.Show, :show
      live "/profile", ProfileLive, :index
    end
  end

  scope "/", Csci379FinalWeb do
    pipe_through [:browser]

    get "/users/log-in", UserSessionController, :new
    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
