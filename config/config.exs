# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# These enable behaviors that will become the default in the next major
# version of Ash. Setting them now opts your application into the new
# behavior and ensures a seamless upgrade. See the backwards compatibility
# guide for an explanation of each setting:
# https://hexdocs.pm/ash/backwards-compatibility-config.html
config :ash,
  allow_forbidden_field_for_relationships_by_default: true,
  include_embedded_source_by_default?: false,
  show_keysets_for_all_actions?: false,
  default_page_type: :keyset,
  policies: [no_filter_static_forbidden_reads?: false],
  keep_read_action_loads_when_loading?: false,
  default_actions_require_atomic?: true,
  read_action_after_action_hooks_in_order?: true,
  bulk_actions_default_to_errors?: true,
  transaction_rollback_on_error?: true,
  redact_sensitive_values_in_errors?: true,
  many_to_many_destroy_destination_on_match?: true,
  known_types: [AshPostgres.Timestamptz, AshPostgres.TimestamptzUsec]

config :ash_oban, pro?: false

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  find_me_a_flat: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# ex_gram's token lives under its own application key; set at runtime.
config :ex_gram, token: nil

# Configure the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :find_me_a_flat, FindMeAFlat.Mailer, adapter: Swoosh.Adapters.Local

# Configure the endpoint
config :find_me_a_flat, FindMeAFlatWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: FindMeAFlatWeb.ErrorHTML, json: FindMeAFlatWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: FindMeAFlat.PubSub,
  live_view: [signing_salt: "Rkw5t3dw"]

# Oban owns scheduling and retries. One queue per kind of work: :crawl fetches
# portals, :deliver sends Telegram messages (concurrency 1, so a 429 snooze paces
# the whole channel), :maintenance runs the cron pulse and housekeeping.
#
# There is deliberately no Oban.Plugins.Pruner here: `GET /healthz` decides it is
# healthy by reading cron enqueues from the last two minutes, and the Pruner's
# default `max_age` of 60 seconds would delete that evidence and make a healthy
# system report 503.
config :find_me_a_flat, Oban,
  engine: Oban.Engines.Basic,
  notifier: Oban.Notifiers.Postgres,
  queues: [crawl: 4, deliver: 1, maintenance: 1],
  repo: FindMeAFlat.Repo,
  plugins: [
    # Rescues jobs orphaned by a killed node so a crawl interrupted mid-run
    # comes back instead of sitting `executing` forever.
    {Oban.Plugins.Lifeline, rescue_after: to_timeout(minute: 30)},
    # The pulse is what `GET /healthz` measures. If cron stops enqueueing it,
    # the endpoint says no.
    {Oban.Plugins.Cron, crontab: [{"* * * * *", FindMeAFlat.Maintenance.PulseWorker}]}
  ]

config :find_me_a_flat,
  ecto_repos: [FindMeAFlat.Repo],
  generators: [timestamp_type: :utc_datetime],
  ash_domains: [
    FindMeAFlat.Reference,
    FindMeAFlat.Portals,
    FindMeAFlat.Listings,
    FindMeAFlat.Searches,
    FindMeAFlat.Accounts
  ]

# The two seams that are doubled in tests, named here so no later slice has to
# invent a config key for them. `Fetching` (S3) and `Bot` (S5) own the modules;
# S1 only declares which one is wired in.
config :find_me_a_flat,
  portal_transport: FindMeAFlat.Fetching.Transport.Req,
  telegram_transport: FindMeAFlat.Bot.Transport.ExGram,
  # Telegram credentials are read from the environment in config/runtime.exs.
  # Declared nil here so a missing environment variable is a nil to check rather
  # than a KeyError at boot.
  telegram_webhook_secret: nil

# The hooks in .git/hooks come from .agents/hooks/install-git-hooks.sh, which makes
# each one cd to the checkout the commit actually happens in — git worktrees share
# a hooks directory, and this library bakes an absolute path. Leave auto_install
# off so `mix compile` cannot overwrite them.
if config_env() == :dev do
  config :git_hooks,
    auto_install: false,
    verbose: true,
    hooks: [
      pre_commit: [tasks: [{:mix_task, :precommit}]],
      pre_push: [tasks: [{:mix_task, :ci}]]
    ]
end

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :spark,
  formatter: [
    remove_parens?: true,
    "Ash.Resource": [
      section_order: [
        :postgres,
        :resource,
        :code_interface,
        :actions,
        :policies,
        :pub_sub,
        :preparations,
        :changes,
        :validations,
        :multitenancy,
        :attributes,
        :relationships,
        :calculations,
        :aggregates,
        :identities
      ]
    ],
    "Ash.Domain": [section_order: [:resources, :policies, :authorization, :domain, :execution]]
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.12",
  find_me_a_flat: [
    # Import environment specific config. This must remain at the bottom
    # of this file so it overrides the configuration defined above.
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

import_config "#{config_env()}.exs"
