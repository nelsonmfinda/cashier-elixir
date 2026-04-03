defmodule Cashier.Test.StubHalfPriceRule do
  @moduledoc false

  defstruct [:product_code]

  defimpl Cashier.Ports.Out.PricingRule do
    def applies_to?(%{product_code: code}, code), do: true
    def applies_to?(_rule, _code), do: false

    def calculate(_rule, quantity, unit_price) do
      Decimal.new(quantity)
      |> Decimal.mult(unit_price)
      |> Decimal.div(Decimal.new(2))
      |> Decimal.round(2)
    end
  end
end
