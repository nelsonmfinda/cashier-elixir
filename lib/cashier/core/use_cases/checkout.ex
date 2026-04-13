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

  @spec build_rule_index([struct()]) :: %{String.t() => struct() | nil}
  def build_rule_index(pricing_rules) do
    pricing_rules
    |> Enum.map(fn rule -> {rule.product_code, rule} end)
    |> Map.new()
  end

  @spec total(Cart.t(), [struct()] | %{String.t() => struct() | nil}) :: Decimal.t()
  def total(%Cart{} = cart, rules) when is_list(rules) do
    cart
    |> Cart.items()
    |> Enum.reduce(Decimal.new("0.00"), fn item, acc ->
      rule = Enum.find(rules, &PricingRule.applies_to?(&1, item.product.code))
      Decimal.add(acc, line_total(item, rule))
    end)
    |> Decimal.round(2)
  end

  def total(%Cart{} = cart, rule_index) when is_map(rule_index) do
    cart
    |> Cart.items()
    |> Enum.reduce(Decimal.new("0.00"), fn item, acc ->
      Decimal.add(acc, line_total(item, Map.get(rule_index, item.product.code)))
    end)
    |> Decimal.round(2)
  end

  defp line_total(item, nil), do: CartItem.subtotal(item)

  defp line_total(item, rule) do
    PricingRule.calculate(rule, item.quantity, item.product.price)
  end
end
