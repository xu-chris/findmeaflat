defmodule FindMeAFlatWeb.Router do
  use FindMeAFlatWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {FindMeAFlatWeb.Layouts, :root}
    plug :protect_from_forgery
    # An explicit Content-Security-Policy, because `put_secure_browser_headers`
    # sets none by default and Phase 1's only browser pages are the generated home
    # page and the dev dashboard. Widen it when a real surface arrives (S16), do not
    # remove it. `ws:` covers live reload and LiveView in development.
    plug :put_secure_browser_headers, %{
      "content-security-policy" =>
        "default-src 'self'; base-uri 'self'; frame-ancestors 'none'; " <>
          "img-src 'self' data:; style-src 'self' 'unsafe-inline'; " <>
          "script-src 'self' 'unsafe-inline'; connect-src 'self' ws: wss:"
    }
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Through no pipeline on purpose. `plug :accepts` would answer a probe that asks
  # for `text/html` with a 406, and a health check that fails on content negotiation
  # reports the prober's habits rather than the system's state. The controller sets
  # the JSON content type itself. config/prod.exs exempts this path from force_ssl
  # for the same reason: a load balancer on plain HTTP needs the answer, not a 301.
  scope "/", FindMeAFlatWeb do
    get "/healthz", HealthController, :show
  end

  scope "/", FindMeAFlatWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", FindMeAFlatWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:find_me_a_flat, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: FindMeAFlatWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
