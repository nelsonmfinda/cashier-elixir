defmodule Cashier.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Cashier.Registry},
      {DynamicSupervisor,
       name: Cashier.SessionSupervisor, strategy: :one_for_one, max_children: 10_000}
    ]

    opts = [strategy: :rest_for_one, name: Cashier.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
