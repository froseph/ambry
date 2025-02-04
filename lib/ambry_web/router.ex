defmodule AmbryWeb.Router do
  @moduledoc false

  use AmbryWeb, :router

  import AmbryWeb.UserAuth
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {AmbryWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :uploads do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_current_user
    plug :fetch_api_user
    plug :require_any_authenticated_user

    # Serve static user uploads
    plug Plug.Static,
      at: "/uploads",
      from: {Ambry.Paths, :uploads_folder_disk_path, []},
      gzip: false,
      only: ~w(media)
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_api_user
  end

  scope "/uploads", AmbryWeb do
    pipe_through :uploads

    get "/*path", FallbackController, :index
  end

  scope "/", AmbryWeb do
    pipe_through [:browser, :require_authenticated_user]

    live "/", HomeLive.Home, :home
    live "/people/:id", PersonLive.Show, :show
    live "/series/:id", SeriesLive.Show, :show
    live "/books/:id", BookLive.Show, :show
    live "/search/:query", SearchLive.Results, :results
  end

  scope "/admin", AmbryWeb.Admin, as: :admin do
    pipe_through [:browser, :require_authenticated_user, :require_admin]

    live "/people", PersonLive.Index, :index
    live "/people/new", PersonLive.Index, :new
    live "/people/:id/edit", PersonLive.Index, :edit

    live "/books", BookLive.Index, :index
    live "/books/new", BookLive.Index, :new
    live "/books/:id/edit", BookLive.Index, :edit

    live "/series", SeriesLive.Index, :index
    live "/series/new", SeriesLive.Index, :new
    live "/series/:id/edit", SeriesLive.Index, :edit

    live "/media", MediaLive.Index, :index
    live "/media/new", MediaLive.Index, :new
    live "/media/:id/edit", MediaLive.Index, :edit
    live "/media/:id/chapters", MediaLive.Index, :chapters

    live "/audit", AuditLive.Index, :index

    live_dashboard "/dashboard", metrics: AmbryWeb.Telemetry
  end

  scope "/api", AmbryWeb.API, as: :api do
    pipe_through [:api]

    post "/log_in", SessionController, :create
  end

  scope "/api", AmbryWeb.API, as: :api do
    pipe_through [:api, :require_authenticated_api_user]

    delete "/log_out", SessionController, :delete

    resources "/books", BookController, only: [:index, :show]
    resources "/people", PersonController, only: [:show]
    resources "/series", SeriesController, only: [:show]
    resources "/player_states", PlayerStateController, only: [:index, :show, :update]
    resources "/bookmarks", BookmarkController, only: [:create, :update, :delete]
    get "/bookmarks/:media_id", BookmarkController, :index
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", AmbryWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", AmbryWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
  end

  scope "/", AmbryWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :edit
    post "/users/confirm/:token", UserConfirmationController, :update
  end
end
