defmodule Cashier.Adapters.Rules.BuyOneGetOneFree do
  @moduledoc """
  Every second item is free, buy 2 pay for 1, buy 3 pay for 2, and so on.

  Set `:product_code` to the code this promotion applies to.

  ## Example

      iex> rule = %Cashier.Adapters.Rules.BuyOneGetOneFree{product_code: "GR1"}
      iex> Cashier.Ports.Out.PricingRule.calculate(rule, 3, Decimal.new("3.11"))
      Decimal.new("6.22")
  """

  @enforce_keys [:product_code]
  defstruct [:product_code]

  @type t :: %__MODULE__{product_code: String.t()}

  defimpl Cashier.Ports.Out.PricingRule do
    def applies_to?(%{product_code: code}, code), do: true
    def applies_to?(_rule, _code), do: false

    def calculate(_rule, 0, _unit_price), do: Decimal.new("0.00")

    def calculate(_rule, quantity, _unit_price) when quantity < 0 do
      raise ArgumentError, "quantity must be non-negative, got: #{quantity}"
    end

    def calculate(_rule, quantity, unit_price) when quantity > 0 do
      charged = div(quantity + 1, 2)

      Decimal.new(charged)
      |> Decimal.mult(unit_price)
      |> Decimal.round(2)
    end
  end
end
