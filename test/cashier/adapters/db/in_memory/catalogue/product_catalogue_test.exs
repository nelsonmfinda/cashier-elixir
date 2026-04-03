defmodule Cashier.Adapters.Db.InMemory.Catalogue.ProductCatalogueTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Cashier.Adapters.Db.InMemory.Catalogue.ProductCatalogue
  alias Cashier.Core.Domain.Product

  describe "fetch/1" do
    test "GR1 returns Green tea product" do
      assert {:ok, %Product{code: "GR1", name: "Green tea", price: price}} =
               ProductCatalogue.fetch("GR1")

      assert Decimal.equal?(price, Decimal.new("3.11"))
    end

    test "SR1 returns Strawberries product" do
      assert {:ok, %Product{code: "SR1"}} = ProductCatalogue.fetch("SR1")
    end

    test "CF1 returns Coffee product" do
      assert {:ok, %Product{code: "CF1"}} = ProductCatalogue.fetch("CF1")
    end

    test "UNKNOWN returns error" do
      assert {:error, :not_found} = ProductCatalogue.fetch("UNKNOWN")
    end
  end
end
