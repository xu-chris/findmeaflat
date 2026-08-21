import Config

config :ash, policies: [show_policy_breakdowns?: true], disable_async?: true

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :ex_gram, token: "test-bot-token"

# In test we don't send emails
# Port 5434 — same server as dev, same reason (see config/dev.exs) and the same
# port the CI service container publishes.
config :find_me_a_flat, FindMeAFlat.Mailer, adapter: Swoosh.Adapters.Test

config :find_me_a_flat, FindMeAFlat.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5434,
  database: "find_me_a_flat_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  # We don't run a server during test. If one is required,
  # you can enable the server option below.
  pool_size: System.schedulers_online() * 2

config :find_me_a_flat, FindMeAFlatWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "JFPnmaCmwhvbR7pjhI5UGNj9qBapeTIkQGFF16Tch9yZizoHbdUGd4W0HT2mSTck",
  server: false

config :find_me_a_flat, Oban, testing: :manual

# Both transports are doubled in tests: the tests that matter replay stored
# portal HTML and assert on the message we would have sent, never on a live site
# or a real chat. S3 and S5 own the stub modules.
config :find_me_a_flat,
  portal_transport: FindMeAFlat.Fetching.Transport.Stub,
  telegram_transport: FindMeAFlat.Bot.Transport.Stub,
  telegram_webhook_secret: "test-webhook-secret"

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false
