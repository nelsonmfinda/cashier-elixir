defmodule Cashier.Adapters.Rules.BuyOneGetOneFreeTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Cashier.Adapters.Rules.BuyOneGetOneFree
  alias Cashier.Ports.Out.PricingRule

  @rule %BuyOneGetOneFree{product_code: "GR1"}
  @price Decimal.new("3.11")

  describe "applies_to?/2" do
    test "returns true for matching product code" do
      assert PricingRule.applies_to?(@rule, "GR1")
    end

    test "returns false for non-matching product code" do
      refute PricingRule.applies_to?(@rule, "SR1")
    end

    test "is reusable with different product codes" do
      rule = %BuyOneGetOneFree{product_code: "TEA1"}
      assert PricingRule.applies_to?(rule, "TEA1")
      refute PricingRule.applies_to?(rule, "GR1")
    end
  end

  describe "calculate/3" do
    test "1 item → 1 × price" do
      assert Decimal.equal?(PricingRule.calculate(@rule, 1, @price), Decimal.new("3.11"))
    end

    test "2 items → 1 × price (second is free)" do
      assert Decimal.equal?(PricingRule.calculate(@rule, 2, @price), Decimal.new("3.11"))
    end

    test "3 items → 2 × price" do
      assert Decimal.equal?(PricingRule.calculate(@rule, 3, @price), Decimal.new("6.22"))
    end

    test "4 items → 2 × price" do
      assert Decimal.equal?(PricingRule.calculate(@rule, 4, @price), Decimal.new("6.22"))
    end
  end
end
