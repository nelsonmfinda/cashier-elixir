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
    rules = [
      %BuyOneGetOneFree{product_code: "GR1"},
      %BulkFixedPrice{product_code: "SR1", threshold: 3, discounted_price: Decimal.new("4.50")},
      %BulkFractionPrice{product_code: "CF1", threshold: 3, numerator: 2, denominator: 3}
    ]

    validate_rules!(rules)
    rules
  end

  @doc "Validates pricing rules configuration. Raises on invalid config."
  @spec validate_rules!([struct()]) :: :ok
  def validate_rules!(rules) do
    codes = Enum.map(rules, & &1.product_code)

    if length(codes) != length(Enum.uniq(codes)) do
      raise ArgumentError, "duplicate product codes in pricing_rules"
    end

    Enum.each(rules, fn rule ->
      validate_threshold!(rule)
      validate_bulk_fraction!(rule)
      validate_product_code!(rule)
    end)

    :ok
  end

  defp validate_threshold!(%{threshold: threshold}) do
    if threshold < 1 do
      raise ArgumentError, "threshold must be at least 1, got: #{threshold}"
    end
  end

  defp validate_threshold!(_), do: :ok

  defp validate_bulk_fraction!(%BulkFractionPrice{denominator: den, numerator: num}) do
    if den <= 0 do
      raise ArgumentError, "denominator must be positive, got: #{den}"
    end

    if num <= 0 do
      raise ArgumentError, "numerator must be positive, got: #{num}"
    end
  end

  defp validate_bulk_fraction!(_), do: :ok

  defp validate_product_code!(%{product_code: code}) do
    if code == "" or String.trim(code) == "" do
      raise ArgumentError, "product_code cannot be empty"
    end
  end
end
