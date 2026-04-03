defmodule Cashier.Core.Domain.CartItem do
  @moduledoc """
  A product paired with how many times it has been scanned.

  Knows how to increment its count and compute a subtotal before
  any pricing rules are applied.
  """

  alias Cashier.Core.Domain.Product

  @enforce_keys [:product, :quantity]
  defstruct [:product, :quantity]

  @type t :: %__MODULE__{
          product: Product.t(),
          quantity: pos_integer()
        }

  @spec new(Product.t()) :: t()
  def new(%Product{} = product) do
    %__MODULE__{product: product, quantity: 1}
  end

  @spec increment(t()) :: t()
  def increment(%__MODULE__{quantity: quantity} = item) do
    %{item | quantity: quantity + 1}
  end

  @spec subtotal(t()) :: Decimal.t()
  def subtotal(%__MODULE__{product: product, quantity: quantity}) do
    Decimal.mult(product.price, quantity)
  end
end
