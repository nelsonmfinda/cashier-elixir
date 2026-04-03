defmodule Cashier.Core.Domain.CartTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Cashier.Core.Domain.{Cart, CartItem, Product}

  describe "new/0" do
    test "creates an empty cart" do
      cart = Cart.new()
      assert Cart.empty?(cart)
    end
  end

  describe "add_item/2" do
    test "single product gets quantity 1" do
      product = Product.new("GR1", "Green tea", Decimal.new("3.11"))
      cart = Cart.new() |> Cart.add_item(product)

      [item] = Cart.items(cart)
      assert item.quantity == 1
      assert item.product.code == "GR1"
    end

    test "same product added 3 times results in quantity 3 and single map entry" do
      product = Product.new("GR1", "Green tea", Decimal.new("3.11"))

      cart =
        Cart.new()
        |> Cart.add_item(product)
        |> Cart.add_item(product)
        |> Cart.add_item(product)

      assert length(Cart.items(cart)) == 1
      [item] = Cart.items(cart)
      assert item.quantity == 3
    end

    test "two different products result in 2 map entries" do
      gr1 = Product.new("GR1", "Green tea", Decimal.new("3.11"))
      sr1 = Product.new("SR1", "Strawberries", Decimal.new("5.00"))

      cart =
        Cart.new()
        |> Cart.add_item(gr1)
        |> Cart.add_item(sr1)

      assert length(Cart.items(cart)) == 2
    end
  end

  describe "CartItem.subtotal/1" do
    test "3 × £3.11 = £9.33" do
      product = Product.new("GR1", "Green tea", Decimal.new("3.11"))

      item =
        CartItem.new(product)
        |> CartItem.increment()
        |> CartItem.increment()

      assert item.quantity == 3
      assert Decimal.equal?(CartItem.subtotal(item), Decimal.new("9.33"))
    end
  end
end
