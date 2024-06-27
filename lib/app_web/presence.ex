defmodule AppWeb.Presence do
  use Phoenix.Presence,
    otp_app: :app,
    pubsub_server: App.PubSub
end
