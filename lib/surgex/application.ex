defmodule Surgex.Application do
  @moduledoc """
  Main Surgex OTP application that calls patches configured for running and hibernates itself.
  """

  use Application
  use GenServer
  require Logger
  alias Surgex.{
    Scout,
    Sentry,
  }
  alias Surgex.Config.Patch

  @doc false
  def start(_type, _args) do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(_) do
    Patch.init()
    Scout.init()
    Sentry.init()

    {:ok, nil, :hibernate}
  end
end
