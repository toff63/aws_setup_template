defmodule HelloWorld.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      %{id: HelloWorld.Greeting, name: HelloWorld.Greeting, start: {HelloWorld.Greeting, :start_link, [[]]}},
      Plug.Cowboy.child_spec(scheme: :http, plug: HelloWorld.Api, options: [port: 4001])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HelloWorld.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
