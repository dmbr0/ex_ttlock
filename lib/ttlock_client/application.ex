defmodule TTlockClient.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Load .env file in development and test environments
    if Mix.env() in [:dev, :test] do
      Dotenv.load()
    end

    children = [
      # Start Finch HTTP client
      {Finch, name: TTlockClient.Finch},
      # Start the authentication manager
      TTlockClient.AuthManager
    ]

    opts = [strategy: :one_for_one, name: TTlockClient.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
