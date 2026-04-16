defmodule Cashier.Adapters.Rules.BulkFixedPrice do
  @moduledoc """
  Drops the unit price to a fixed amount when you buy enough.

  For example, strawberries normally cost £5.00 each, but buying 3 or more
  brings the price down to £4.50 each. Configure `:threshold` and
  `:discounted_price` to set where the discount kicks in and what it becomes.

  ## Example

      iex> rule = %Cashier.Adapters.Rules.BulkFixedPrice{
      ...>   product_code: "SR1",
      ...>   threshold: 3,
      ...>   discounted_price: Decimal.new("4.50")
      ...> }
      iex> Cashier.Ports.Out.PricingRule.calculate(rule, 3, Decimal.new("5.00"))
      Decimal.new("13.50")
  """

  @enforce_keys [:product_code, :threshold, :discounted_price]
  defstruct [:product_code, :threshold, :discounted_price]

  @type t :: %__MODULE__{
          product_code: String.t(),
          threshold: pos_integer(),
          discounted_price: Decimal.t()
        }

  defimpl Cashier.Ports.Out.PricingRule do
    def applies_to?(%{product_code: code}, code), do: true
    def applies_to?(_rule, _code), do: false

    def calculate(_rule, 0, _unit_price), do: Decimal.new("0.00")

    def calculate(_rule, quantity, _unit_price) when quantity < 0 do
      raise ArgumentError, "quantity must be non-negative, got: #{quantity}"
    end

    def calculate(
          %{threshold: threshold, discounted_price: discounted_price},
          quantity,
          _unit_price
        )
        when quantity > 0 and quantity >= threshold do
      Decimal.mult(Decimal.new(quantity), discounted_price)
    end

    def calculate(_rule, quantity, unit_price) when quantity > 0 do
      Decimal.mult(Decimal.new(quantity), unit_price)
    end
  end
end
