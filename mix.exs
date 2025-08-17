defmodule TTlockClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_ttlock,
      version: "0.1.3",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "TTlockClient",
      description: "Elixir client library for TTLock Open Platform API",
      package: package(),
      docs: docs(),
      aliases: aliases(),
      preferred_cli_env: [
        "test.watch": :test,
        "test.coverage": :test
      ],
      test_coverage: [tool: ExCoveralls],
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        plt_add_apps: [:ex_unit]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {TTlockClient.Application, []}
    ]
  end

  defp deps do
    [
      # HTTP client
      {:finch, "~> 0.16"},

      # JSON handling
      {:jason, "~> 1.4"},

      # Environment variables from .env file
      {:dotenv, "~> 3.1", only: [:dev, :test]},

      # Development and testing
      {:ex_doc, "~> 0.30", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:castore, "~> 1.0", only: :test},
      {:bypass, "~> 2.1", only: :test},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      description: "Elixir client library for TTLock Open Platform API with centralized OAuth management",
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/your_username/ex_ttlock",
        "Documentation" => "https://hexdocs.pm/ex_ttlock"
      },
      maintainers: ["Your Name"],
      files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end

  defp docs do
    [
      main: "TTlockClient",
      extras: [
        "README.md",
        "CHANGELOG.md"
      ],
      groups_for_modules: [
        "Core API": [TTlockClient],
        "Authentication": [TTlockClient.AuthManager, TTlockClient.OAuthClient],
        "Types": [TTlockClient.Types],
        "Application": [TTlockClient.Application]
      ]
    ]
  end

  defp aliases do
    [
      "test.watch": ["test.watch --stale"],
      "test.coverage": ["coveralls.html"],
      "test.ci": ["coveralls.json"],
      quality: ["format", "credo --strict", "dialyzer"],
      "quality.fix": ["format", "credo --strict --fix-all"]
    ]
  end
end
