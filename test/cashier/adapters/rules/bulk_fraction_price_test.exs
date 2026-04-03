defmodule Cashier.Adapters.Rules.BulkFractionPriceTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Cashier.Adapters.Rules.BulkFractionPrice
  alias Cashier.Ports.Out.PricingRule

  @rule %BulkFractionPrice{
    product_code: "CF1",
    threshold: 3,
    numerator: 2,
    denominator: 3
  }
  @price Decimal.new("11.23")

  describe "applies_to?/2" do
    test "returns true for matching product code" do
      assert PricingRule.applies_to?(@rule, "CF1")
    end

    test "returns false for non-matching product code" do
      refute PricingRule.applies_to?(@rule, "SR1")
    end
  end

  describe "calculate/3" do
    test "below threshold → full price" do
      result = PricingRule.calculate(@rule, 2, @price)
      assert Decimal.compare(result, Decimal.new("22.46")) == :eq
    end

    test "at threshold → fraction applied and rounded" do
      result = PricingRule.calculate(@rule, 3, @price)
      assert Decimal.compare(result, Decimal.new("22.46")) == :eq
    end

    test "is reusable with different fractions" do
      half_off = %BulkFractionPrice{
        product_code: "X1",
        threshold: 2,
        numerator: 1,
        denominator: 2
      }

      # 3 × £10.00 × 1/2 = £15.00
      result = PricingRule.calculate(half_off, 3, Decimal.new("10.00"))
      assert Decimal.compare(result, Decimal.new("15.00")) == :eq
    end
  end
end
