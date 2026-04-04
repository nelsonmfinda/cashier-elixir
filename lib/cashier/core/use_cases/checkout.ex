defmodule Cashier.Core.UseCases.Checkout do
  @moduledoc """
  Handles scanning products into a cart and computing the total.

  This module sits in the core layer, it knows nothing about GenServers,
  databases, or which concrete rules exist. The catalogue and pricing rules
  are injected by the caller, keeping this module easy to test in isolation.
  """

  alias Cashier.Core.Domain.{Cart, CartItem}
  alias Cashier.Ports.Out.PricingRule

  @spec scan(Cart.t(), String.t(), module()) ::
          {:ok, Cart.t()} | {:error, {:product_not_found, String.t()}}
  def scan(%Cart{} = cart, code, catalogue) do
    case catalogue.fetch(code) do
      {:ok, product} -> {:ok, Cart.add_item(cart, product)}
      {:error, :not_found} -> {:error, {:product_not_found, code}}
    end
  end

  @spec total(Cart.t(), [struct()]) :: Decimal.t()
  def total(%Cart{} = cart, pricing_rules) do
    items = Cart.items(cart)
    rule_index = index_rules(items, pricing_rules)

    items
    |> Enum.reduce(Decimal.new("0.00"), fn item, acc ->
      Decimal.add(acc, line_total(item, Map.get(rule_index, item.product.code)))
    end)
    |> Decimal.round(2)
  end

  defp index_rules(items, pricing_rules) do
    items
    |> Enum.map(& &1.product.code)
    |> Enum.uniq()
    |> Map.new(fn code ->
      {code, Enum.find(pricing_rules, &PricingRule.applies_to?(&1, code))}
    end)
  end

  defp line_total(item, nil), do: CartItem.subtotal(item)

  defp line_total(item, rule) do
    PricingRule.calculate(rule, item.quantity, item.product.price)
  end
end
