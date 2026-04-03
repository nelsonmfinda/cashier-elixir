import Config

config :git_hooks,
  auto_install: true,
  verbose: true,
  hooks: [
    pre_commit: [
      tasks: [
        {:cmd, "mix compile --warnings-as-errors"},
        {:cmd, "mix format --check-formatted"},
        {:cmd, "mix credo --strict"},
        {:cmd, "mix test"}
      ]
    ],
    pre_push: [
      tasks: [
        {:cmd, "mix dialyzer"}
      ]
    ]
  ]
