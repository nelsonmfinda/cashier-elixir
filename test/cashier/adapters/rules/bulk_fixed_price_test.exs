defmodule Cashier.Adapters.Rules.BulkFixedPriceTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Cashier.Adapters.Rules.BulkFixedPrice
  alias Cashier.Ports.Out.PricingRule

  @rule %BulkFixedPrice{
    product_code: "SR1",
    threshold: 3,
    discounted_price: Decimal.new("4.50")
  }
  @price Decimal.new("5.00")

  describe "applies_to?/2" do
    test "returns true for matching product code" do
      assert PricingRule.applies_to?(@rule, "SR1")
    end

    test "returns false for non-matching product code" do
      refute PricingRule.applies_to?(@rule, "GR1")
    end

    test "is reusable with different product codes and thresholds" do
      rule = %BulkFixedPrice{
        product_code: "FRUIT1",
        threshold: 5,
        discounted_price: Decimal.new("2.00")
      }

      assert PricingRule.applies_to?(rule, "FRUIT1")
      refute PricingRule.applies_to?(rule, "SR1")
    end
  end

  describe "calculate/3" do
    test "below threshold → full price" do
      assert Decimal.equal?(PricingRule.calculate(@rule, 2, @price), Decimal.new("10.00"))
    end

    test "at threshold → discounted price" do
      assert Decimal.equal?(PricingRule.calculate(@rule, 3, @price), Decimal.new("13.50"))
    end

    test "above threshold → discounted price" do
      assert Decimal.equal?(PricingRule.calculate(@rule, 5, @price), Decimal.new("22.50"))
    end
  end
end
