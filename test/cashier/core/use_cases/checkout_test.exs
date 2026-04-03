defmodule Cashier.Core.UseCases.CheckoutTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Cashier.Core.Domain.Cart
  alias Cashier.Core.UseCases.Checkout

  @catalogue Cashier.Test.StubCatalogue
  @half_price_rule %Cashier.Test.StubHalfPriceRule{product_code: "P1"}

  describe "scan/3" do
    test "valid code adds item to cart" do
      {:ok, cart} = Checkout.scan(Cart.new(), "P1", @catalogue)
      [item] = Cart.items(cart)
      assert item.product.code == "P1"
      assert item.quantity == 1
    end

    test "unknown code returns error" do
      assert {:error, {:product_not_found, "UNKNOWN"}} =
               Checkout.scan(Cart.new(), "UNKNOWN", @catalogue)
    end
  end

  describe "total/2" do
    test "with no rules returns full price" do
      {:ok, cart} = Checkout.scan(Cart.new(), "P1", @catalogue)
      assert Checkout.total(cart, []) == Decimal.new("10.00")
    end

    test "with a stub rule applies discount" do
      {:ok, cart} = Checkout.scan(Cart.new(), "P1", @catalogue)
      {:ok, cart} = Checkout.scan(cart, "P1", @catalogue)

      # 2 × £10.00 / 2 = £10.00
      assert Decimal.equal?(Checkout.total(cart, [@half_price_rule]), Decimal.new("10.00"))
    end

    test "empty cart returns 0.00" do
      assert Checkout.total(Cart.new(), []) == Decimal.new("0.00")
    end
  end
end
