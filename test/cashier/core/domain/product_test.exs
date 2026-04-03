defmodule Cashier.Core.Domain.ProductTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Cashier.Core.Domain.Product

  describe "new/3" do
    test "fields are set correctly" do
      product = Product.new("GR1", "Green tea", Decimal.new("3.11"))

      assert product.code == "GR1"
      assert product.name == "Green tea"
      assert Decimal.equal?(product.price, Decimal.new("3.11"))
    end

    test "raises FunctionClauseError if price is not a Decimal" do
      assert_raise FunctionClauseError, fn ->
        Product.new("GR1", "Green tea", 3.11)
      end
    end

    test "raises ArgumentError if price is negative" do
      assert_raise ArgumentError, ~r/non-negative/, fn ->
        Product.new("GR1", "Green tea", Decimal.new("-1.00"))
      end
    end

    test "accepts zero price" do
      product = Product.new("FREE", "Free item", Decimal.new("0.00"))
      assert Decimal.equal?(product.price, Decimal.new("0.00"))
    end
  end
end
