defmodule Cashier do
  @moduledoc """
  Entry point for the cashier service.

  Start a checkout session, scan products, and get the total, all
  through this module. Everything else is an implementation detail.

  ## Example

      {:ok, session} = Cashier.new_checkout()
      Cashier.scan(session, "GR1")
      Cashier.scan(session, "GR1")
      Cashier.scan(session, "SR1")
      Cashier.formatted_total(session)
      #=> "£8.11"
  """

  alias Cashier.{CheckoutSession, Session}

  @spec new_checkout(keyword()) :: {:ok, Session.t()} | {:error, term()}
  def new_checkout(opts \\ []) do
    CheckoutSession.new(opts)
  end

  @spec scan(Session.t(), String.t()) :: :ok | {:error, {:product_not_found, String.t()}}
  def scan(%Session{id: id}, code), do: CheckoutSession.scan(id, code)

  @spec total(Session.t()) :: Decimal.t()
  def total(%Session{id: id}), do: CheckoutSession.total(id)

  @spec formatted_total(Session.t()) :: String.t()
  def formatted_total(%Session{id: id}), do: CheckoutSession.formatted_total(id)

  @spec clear(Session.t()) :: :ok
  def clear(%Session{id: id}), do: CheckoutSession.clear(id)

  @spec stop(Session.t()) :: :ok
  def stop(%Session{id: id}), do: CheckoutSession.stop(id)

  @spec alive?(Session.t()) :: boolean()
  def alive?(%Session{id: id}), do: CheckoutSession.alive?(id)
end
