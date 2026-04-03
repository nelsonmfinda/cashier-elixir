defmodule Cashier.Adapters.Db.InMemory.Catalogue.ProductCatalogue do
  @moduledoc """
  Keeps the product catalogue as a compile time map, no database needed.
  """

  @behaviour Cashier.Ports.Out.ProductCatalogue

  alias Cashier.Core.Domain.Product

  @products %{
    "GR1" => Product.new("GR1", "Green tea", Decimal.new("3.11")),
    "SR1" => Product.new("SR1", "Strawberries", Decimal.new("5.00")),
    "CF1" => Product.new("CF1", "Coffee", Decimal.new("11.23"))
  }

  @impl true
  def fetch(code) do
    case Map.fetch(@products, code) do
      {:ok, product} -> {:ok, product}
      :error -> {:error, :not_found}
    end
  end
end
