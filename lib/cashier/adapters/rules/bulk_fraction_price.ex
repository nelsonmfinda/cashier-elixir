defmodule Cashier.Adapters.Rules.BulkFractionPrice do
  @moduledoc """
  Multiplies the total by a fraction when you buy enough.

  For example, coffee is normally £11.23 each, but buying 3 or more means
  you pay only 2/3 of the full price. Set `:numerator` and `:denominator`
  to control the fraction, and `:threshold` for the minimum quantity.

  ## Example

      iex> rule = %Cashier.Adapters.Rules.BulkFractionPrice{
      ...>   product_code: "CF1",
      ...>   threshold: 3,
      ...>   numerator: 2,
      ...>   denominator: 3
      ...> }
      iex> Cashier.Ports.Out.PricingRule.applies_to?(rule, "CF1")
      true
  """

  @enforce_keys [:product_code, :threshold, :numerator, :denominator]
  defstruct [:product_code, :threshold, :numerator, :denominator]

  @type t :: %__MODULE__{
          product_code: String.t(),
          threshold: pos_integer(),
          numerator: pos_integer(),
          denominator: pos_integer()
        }

  defimpl Cashier.Ports.Out.PricingRule do
    def applies_to?(%{product_code: code}, code), do: true
    def applies_to?(_rule, _code), do: false

    def calculate(_rule, 0, _unit_price), do: Decimal.new("0.00")

    def calculate(_rule, quantity, _unit_price) when quantity < 0 do
      raise ArgumentError, "quantity must be non-negative, got: #{quantity}"
    end

    def calculate(%{threshold: threshold, numerator: num, denominator: den}, quantity, unit_price)
        when quantity > 0 and quantity >= threshold and den > 0 do
      Decimal.new(quantity)
      |> Decimal.mult(unit_price)
      |> Decimal.mult(Decimal.new(num))
      |> Decimal.div(Decimal.new(den))
      |> Decimal.round(2)
    end

    def calculate(_rule, quantity, unit_price) when quantity > 0 do
      Decimal.new(quantity)
      |> Decimal.mult(unit_price)
      |> Decimal.round(2)
    end
  end
end
