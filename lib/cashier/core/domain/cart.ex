defmodule Cashier.Core.Domain.Cart do
  @moduledoc """
  A shopping cart that groups scanned products by code and tracks quantities.

  The cart is immutable, every operation returns a new cart rather than
  mutating state. Items are keyed by product code so scanning the same
  product twice increments the quantity instead of adding a duplicate.

  ## Example

      iex> alias Cashier.Core.Domain.{Cart, Product}
      iex> product = Product.new("GR1", "Green tea", Decimal.new("3.11"))
      iex> cart = Cart.new() |> Cart.add_item(product) |> Cart.add_item(product)
      iex> [item] = Cart.items(cart)
      iex> item.quantity
      2
  """

  alias Cashier.Core.Domain.{CartItem, Product}

  defstruct items: %{}

  @type t :: %__MODULE__{
          items: %{String.t() => CartItem.t()}
        }

  @spec new() :: t()
  def new, do: %__MODULE__{}

  @spec add_item(t(), Product.t()) :: t()
  def add_item(%__MODULE__{items: items} = cart, %Product{} = product) do
    updated_items =
      Map.update(items, product.code, CartItem.new(product), &CartItem.increment/1)

    %{cart | items: updated_items}
  end

  @spec items(t()) :: [CartItem.t()]
  def items(%__MODULE__{items: items}), do: Map.values(items)

  @spec empty?(t()) :: boolean()
  def empty?(%__MODULE__{items: items}), do: map_size(items) == 0
end
