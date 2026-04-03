defmodule Cashier.CheckoutSession do
  @moduledoc """
  Manages a single checkout as a supervised process.

  Each session holds its own cart, talks to the catalogue and pricing rules
  injected at creation time, and shuts itself down after sitting idle too long.
  Sessions are registered by ID in `Cashier.Registry`, so callers never deal
  with raw PIDs.
  """

  use GenServer, restart: :temporary

  alias Cashier.Core.Domain.Cart
  alias Cashier.Core.UseCases.Checkout
  alias Cashier.{Defaults, PriceFormatter, Session}

  defmodule State do
    @moduledoc "Internal state struct for a checkout session process."

    @enforce_keys [:id, :cart, :catalogue, :pricing_rules, :idle_timeout]
    defstruct [:id, :cart, :catalogue, :pricing_rules, :idle_timeout]

    @type t :: %__MODULE__{
            id: String.t(),
            cart: Cart.t(),
            catalogue: module(),
            pricing_rules: [struct()],
            idle_timeout: timeout()
          }
  end

  @default_idle_timeout :timer.minutes(30)
  @max_code_length 32

  @doc """
  Creates a new checkout session under the `DynamicSupervisor`.

  ## Options

    * `:catalogue` — module implementing `ProductCatalogue` (default: see `Cashier.Defaults`)
    * `:pricing_rules` — list of pricing rule structs (default: see `Cashier.Defaults`)
    * `:idle_timeout` — milliseconds before the session auto-terminates (default: 30 min)
  """
  @spec new(keyword()) :: {:ok, Session.t()} | {:error, term()}
  def new(opts \\ []) do
    id = generate_id()
    catalogue = Keyword.get(opts, :catalogue, Defaults.catalogue())
    pricing_rules = Keyword.get(opts, :pricing_rules, Defaults.pricing_rules())
    idle_timeout = Keyword.get(opts, :idle_timeout, @default_idle_timeout)

    state = %State{
      id: id,
      cart: Cart.new(),
      catalogue: catalogue,
      pricing_rules: pricing_rules,
      idle_timeout: idle_timeout
    }

    case DynamicSupervisor.start_child(Cashier.SessionSupervisor, {__MODULE__, state}) do
      {:ok, _pid} -> {:ok, %Session{id: id}}
      error -> error
    end
  end

  @doc "Scans a product code into the session's cart."
  @spec scan(String.t(), String.t()) :: :ok | {:error, {:product_not_found, String.t()}}
  def scan(id, code) when is_binary(code) and byte_size(code) in 1..@max_code_length do
    GenServer.call(via(id), {:scan, code})
  end

  @doc "Returns the total price as a `Decimal`, with all pricing rules applied."
  @spec total(String.t()) :: Decimal.t()
  def total(id), do: GenServer.call(via(id), :total)

  @doc "Returns the total price formatted as a string (e.g. `\"£22.45\"`)."
  @spec formatted_total(String.t()) :: String.t()
  def formatted_total(id), do: GenServer.call(via(id), :formatted_total)

  @doc "Resets the session's cart to empty."
  @spec clear(String.t()) :: :ok
  def clear(id), do: GenServer.call(via(id), :clear)

  @doc "Terminates the session process."
  @spec stop(String.t()) :: :ok
  def stop(id), do: GenServer.stop(via(id))

  @doc "Returns `true` if the session process is still alive."
  @spec alive?(String.t()) :: boolean()
  def alive?(id) do
    case Registry.lookup(Cashier.Registry, id) do
      [{pid, _}] -> Process.alive?(pid)
      [] -> false
    end
  end

  @doc false
  @spec start_link(State.t()) :: GenServer.on_start()
  def start_link(%State{} = state) do
    GenServer.start_link(__MODULE__, state, name: via(state.id))
  end

  @impl true
  def init(%State{idle_timeout: timeout} = state) do
    {:ok, state, timeout}
  end

  @impl true
  def handle_call({:scan, code}, _from, %State{cart: cart, catalogue: catalogue} = state) do
    case Checkout.scan(cart, code, catalogue) do
      {:ok, updated_cart} ->
        {:reply, :ok, %State{state | cart: updated_cart}, state.idle_timeout}

      {:error, _reason} = error ->
        {:reply, error, state, state.idle_timeout}
    end
  end

  def handle_call(:total, _from, %State{cart: cart, pricing_rules: rules} = state) do
    {:reply, Checkout.total(cart, rules), state, state.idle_timeout}
  end

  def handle_call(:formatted_total, _from, %State{cart: cart, pricing_rules: rules} = state) do
    total = Checkout.total(cart, rules)
    {:reply, PriceFormatter.format(total), state, state.idle_timeout}
  end

  def handle_call(:clear, _from, %State{} = state) do
    {:reply, :ok, %State{state | cart: Cart.new()}, state.idle_timeout}
  end

  @impl true
  def handle_info(:timeout, state) do
    {:stop, :normal, state}
  end

  @impl true
  def handle_info(_msg, state), do: {:noreply, state, state.idle_timeout}

  defp via(id), do: {:via, Registry, {Cashier.Registry, id}}

  defp generate_id do
    :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
  end
end
