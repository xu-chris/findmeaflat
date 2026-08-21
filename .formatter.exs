[
  import_deps: [
    :ash_oban,
    :oban,
    :ash_phoenix,
    :ash_postgres,
    :ash,
    :reactor,
    :ecto,
    :ecto_sql,
    :phoenix
  ],
  subdirectories: ["priv/*/migrations"],
  # Quokka is a Styler fork that reads .credo.exs, so the formatter and the linter
  # cannot disagree about style (QUALITY-GATES.md §4). Keep it last: it rewrites the
  # AST, and the other two only format.
  plugins: [Spark.Formatter, Phoenix.LiveView.HTMLFormatter, Quokka],
  inputs: ["*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}", "priv/*/seeds.exs"]
]
