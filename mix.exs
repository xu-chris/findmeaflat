defmodule FindMeAFlat.MixProject do
  use Mix.Project

  def project do
    [
      app: :find_me_a_flat,
      version: "0.1.0",
      # Pinned to the exact line in .tool-versions: .github/scripts/extract_versions.sh
      # reads this value to choose the CI toolchain, so a loose pin here silently
      # tests on a different Elixir than the one anyone develops against.
      elixir: "~> 1.20.1",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      listeners: [Phoenix.CodeReloader],
      consolidate_protocols: Mix.env() != :dev
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {FindMeAFlat.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  def cli do
    [
      preferred_envs: [precommit: :test, ci: :test]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:sourceror, "~> 1.8", only: [:dev, :test]},
      {:oban, "~> 2.0"},
      {:ash_oban, "~> 0.8"},
      {:ash_phoenix, "~> 2.0"},
      {:ash_postgres, "~> 2.0"},
      {:ash, "~> 3.0"},
      {:igniter, "~> 0.6", only: [:dev, :test]},
      {:phoenix, "~> 1.8.7"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.1.0"},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.3", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.2.0",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:swoosh, "~> 1.16"},
      {:req, "~> 0.5"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 1.0"},
      {:jason, "~> 1.2"},
      {:floki, "~> 0.38"},
      {:ex_gram, "~> 0.55"},
      {:dns_cluster, "~> 0.2.0"},
      {:bandit, "~> 1.5"},

      # Security. exploit_guard is deliberately absent: one 2023 release, a runtime
      # dependency, and the wrong threat model (QUALITY-GATES.md §3).
      {:sobelow, "~> 0.15", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},

      # Migration safety. Ash generates the migrations, so nobody reviews them line
      # by line; this is the check that catches a lock or a rewrite on a table
      # holding a year of listings.
      {:excellent_migrations, "~> 0.1", only: [:dev, :test], runtime: false},

      # Style and semantic linting. Quokka, not Styler: it is a fork that reads
      # .credo.exs, so formatting and linting cannot disagree (QUALITY-GATES.md §4).
      {:quokka, "~> 2.13", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},

      # Runs `mix precommit` and `mix ci` from the hooks that
      # .agents/hooks/install-git-hooks.sh writes. auto_install is off in
      # config/config.exs: those hooks are worktree-aware and this library's are not.
      {:git_hooks, "~> 0.9", only: [:dev], runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ash.setup", "assets.setup", "assets.build", "run priv/repo/seeds.exs"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ash.setup --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["compile", "tailwind find_me_a_flat", "esbuild find_me_a_flat"],
      "assets.deploy": [
        "tailwind find_me_a_flat --minify",
        "esbuild find_me_a_flat --minify",
        "phx.digest"
      ],
      precommit: ["compile --warnings-as-errors", "deps.unlock --unused", "format", "test"],
      # The canonical gate. .github/workflows/ci.yml and the pre-push hook both run
      # this exact alias, so a green push and a green CI mean the same thing.
      ci: [
        "compile --warnings-as-errors",
        "deps.unlock --check-unused",
        "format --check-formatted",
        "credo --strict",
        "sobelow --exit high",
        "deps.audit",
        # Through `cmd`: run from inside an alias, `hex.audit` resolves to no task
        # (Mix loses the Hex archive's tasks there), and a gate step that silently
        # cannot run is worse than one that is absent.
        "cmd mix hex.audit",
        "excellent_migrations.check_safety",
        "test"
      ]
    ]
  end
end
