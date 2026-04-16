defmodule Cashier.DefaultsTest do
  use ExUnit.Case, async: true

  alias Cashier.Adapters.Rules.{BulkFixedPrice, BulkFractionPrice, BuyOneGetOneFree}
  alias Cashier.Defaults

  describe "pricing_rules/0" do
    test "returns default rules with valid configuration" do
      rules = Defaults.pricing_rules()
      assert length(rules) == 3
    end

    test "each product code has unique rule" do
      codes = Enum.map(Defaults.pricing_rules(), & &1.product_code)
      assert codes == Enum.uniq(codes)
    end
  end

  describe "validation" do
    test "duplicate product codes raise ArgumentError" do
      rules = [
        %BuyOneGetOneFree{product_code: "GR1"},
        %BuyOneGetOneFree{product_code: "GR1"}
      ]

      assert_raise ArgumentError, fn ->
        Defaults.validate_rules!(rules)
      end
    end

    test "zero threshold raises ArgumentError" do
      rules = [
        %BulkFixedPrice{product_code: "TEST", threshold: 0, discounted_price: Decimal.new("1.00")}
      ]

      assert_raise ArgumentError, ~r/threshold/, fn ->
        Defaults.validate_rules!(rules)
      end
    end

    test "negative threshold raises ArgumentError" do
      rules = [
        %BulkFixedPrice{
          product_code: "TEST",
          threshold: -1,
          discounted_price: Decimal.new("1.00")
        }
      ]

      assert_raise ArgumentError, ~r/threshold/, fn ->
        Defaults.validate_rules!(rules)
      end
    end

    test "zero denominator raises ArgumentError" do
      rules = [
        %BulkFractionPrice{product_code: "TEST", threshold: 3, numerator: 2, denominator: 0}
      ]

      assert_raise ArgumentError, ~r/denominator/, fn ->
        Defaults.validate_rules!(rules)
      end
    end

    test "negative denominator raises ArgumentError" do
      rules = [
        %BulkFractionPrice{product_code: "TEST", threshold: 3, numerator: 2, denominator: -1}
      ]

      assert_raise ArgumentError, ~r/denominator/, fn ->
        Defaults.validate_rules!(rules)
      end
    end

    test "zero numerator raises ArgumentError" do
      rules = [
        %BulkFractionPrice{product_code: "TEST", threshold: 3, numerator: 0, denominator: 3}
      ]

      assert_raise ArgumentError, ~r/numerator/, fn ->
        Defaults.validate_rules!(rules)
      end
    end

    test "empty product_code raises ArgumentError" do
      rules = [
        %BuyOneGetOneFree{product_code: ""}
      ]

      assert_raise ArgumentError, ~r/product_code/, fn ->
        Defaults.validate_rules!(rules)
      end
    end

    test "whitespace-only product_code raises ArgumentError" do
      rules = [
        %BuyOneGetOneFree{product_code: "   "}
      ]

      assert_raise ArgumentError, ~r/product_code/, fn ->
        Defaults.validate_rules!(rules)
      end
    end
  end
end
