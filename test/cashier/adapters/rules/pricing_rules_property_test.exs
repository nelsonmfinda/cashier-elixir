defmodule Cashier.Adapters.Rules.PricingRulesPropertyTest do
  @moduledoc false

  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Cashier.Adapters.Rules.{BulkFixedPrice, BulkFractionPrice, BuyOneGetOneFree}
  alias Cashier.Ports.Out.PricingRule

  defp positive_quantity, do: positive_integer()

  defp positive_price do
    gen all(cents <- integer(1..100_000)) do
      Decimal.new(1) |> Decimal.mult(Decimal.new(cents)) |> Decimal.div(Decimal.new(100))
    end
  end

  describe "BuyOneGetOneFree properties" do
    @rule %BuyOneGetOneFree{product_code: "X"}

    property "charged quantity is ceil(quantity / 2)" do
      check all(
              quantity <- positive_quantity(),
              price <- positive_price()
            ) do
        result = PricingRule.calculate(@rule, quantity, price)
        charged = div(quantity + 1, 2)
        expected = Decimal.new(charged) |> Decimal.mult(price) |> Decimal.round(2)

        assert Decimal.equal?(result, expected)
      end
    end

    property "result is always less than or equal to full price" do
      check all(
              quantity <- positive_quantity(),
              price <- positive_price()
            ) do
        result = PricingRule.calculate(@rule, quantity, price)
        full = Decimal.new(quantity) |> Decimal.mult(price) |> Decimal.round(2)

        assert Decimal.compare(result, full) in [:lt, :eq]
      end
    end

    property "result is always non-negative" do
      check all(
              quantity <- positive_quantity(),
              price <- positive_price()
            ) do
        result = PricingRule.calculate(@rule, quantity, price)
        refute Decimal.negative?(result)
      end
    end
  end

  describe "BulkFixedPrice properties" do
    property "below threshold uses original price" do
      check all(
              threshold <- integer(2..20),
              quantity <- integer(1..(threshold - 1)),
              price <- positive_price()
            ) do
        rule = %BulkFixedPrice{
          product_code: "X",
          threshold: threshold,
          discounted_price: Decimal.new("1.00")
        }

        result = PricingRule.calculate(rule, quantity, price)
        expected = Decimal.new(quantity) |> Decimal.mult(price) |> Decimal.round(2)

        assert Decimal.equal?(result, expected)
      end
    end

    property "at or above threshold uses discounted price" do
      check all(
              threshold <- integer(2..10),
              extra <- integer(0..50),
              discounted_cents <- integer(1..1000)
            ) do
        quantity = threshold + extra
        discounted_price = Decimal.div(Decimal.new(discounted_cents), Decimal.new(100))

        rule = %BulkFixedPrice{
          product_code: "X",
          threshold: threshold,
          discounted_price: discounted_price
        }

        result = PricingRule.calculate(rule, quantity, Decimal.new("99.99"))
        expected = Decimal.new(quantity) |> Decimal.mult(discounted_price)

        assert Decimal.equal?(result, expected)
      end
    end
  end

  # BulkFractionPrice properties

  describe "BulkFractionPrice properties" do
    property "below threshold uses full price" do
      check all(
              threshold <- integer(2..20),
              quantity <- integer(1..(threshold - 1)),
              price <- positive_price()
            ) do
        rule = %BulkFractionPrice{
          product_code: "X",
          threshold: threshold,
          numerator: 2,
          denominator: 3
        }

        result = PricingRule.calculate(rule, quantity, price)
        expected = Decimal.new(quantity) |> Decimal.mult(price)

        assert Decimal.equal?(result, expected)
      end
    end

    property "at or above threshold applies fraction correctly" do
      check all(
              threshold <- integer(2..10),
              extra <- integer(0..50),
              price <- positive_price(),
              numerator <- integer(1..9),
              denominator <- integer(1..9),
              denominator > 0
            ) do
        quantity = threshold + extra

        rule = %BulkFractionPrice{
          product_code: "X",
          threshold: threshold,
          numerator: numerator,
          denominator: denominator
        }

        result = PricingRule.calculate(rule, quantity, price)

        expected =
          price
          |> Decimal.mult(Decimal.new(quantity))
          |> Decimal.mult(Decimal.new(numerator))
          |> Decimal.div(Decimal.new(denominator))

        assert Decimal.equal?(result, expected)
      end
    end

    property "with numerator < denominator, discounted total is less than full total" do
      check all(
              quantity <- integer(3..100),
              price <- positive_price()
            ) do
        rule = %BulkFractionPrice{
          product_code: "X",
          threshold: 3,
          numerator: 2,
          denominator: 3
        }

        result = PricingRule.calculate(rule, quantity, price)
        full = Decimal.new(quantity) |> Decimal.mult(price)

        assert Decimal.compare(result, full) in [:lt, :eq]
      end
    end
  end
end
