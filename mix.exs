defmodule TTlockClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_ttlock,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/dmbr0/ex_ttlock",
      docs: [
        main: "TTlockClient",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :inets, :ssl]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 2.0"},
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp description do
    "An Elixir client library for TTLock API integration, providing OAuth authentication, lock management, and passcode management functionality."
  end

  defp package do
    [
      name: "ex_ttlock",
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE),
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/dmbr0/ex_ttlock"
      },
      maintainers: ["Alex Whitney"]
    ]
  end
end
