defmodule Cashier.Defaults do
  @moduledoc """
  The out of the box catalogue and pricing rules.

  This is the only place that knows which products and promotions the
  supermarket currently offers. Changing a rule or swapping the catalogue
  means editing this module, nothing else needs to move.
  """

  alias Cashier.Adapters.Db.InMemory.Catalogue.ProductCatalogue
  alias Cashier.Adapters.Rules.{BulkFixedPrice, BulkFractionPrice, BuyOneGetOneFree}

  @doc "Returns the default product catalogue module."
  @spec catalogue() :: module()
  def catalogue, do: ProductCatalogue

  @doc "Returns the default list of pricing rule structs."
  @spec pricing_rules() :: [struct()]
  def pricing_rules do
    [
      %BuyOneGetOneFree{product_code: "GR1"},
      %BulkFixedPrice{product_code: "SR1", threshold: 3, discounted_price: Decimal.new("4.50")},
      %BulkFractionPrice{product_code: "CF1", threshold: 3, numerator: 2, denominator: 3}
    ]
  end
end
