import Config

config :ex_ttlock,
  client_id: System.get_env("TTLOCK_CLIENT_ID"),
  client_secret: System.get_env("TTLOCK_CLIENT_SECRET"),
  username: System.get_env("TTLOCK_USERNAME"),
  password: System.get_env("TTLOCK_PASSWORD")

# Import environment specific config
import_config "#{config_env()}.exs"