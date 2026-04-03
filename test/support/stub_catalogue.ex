defmodule Cashier.Test.StubCatalogue do
  @moduledoc false

  @behaviour Cashier.Ports.Out.ProductCatalogue

  alias Cashier.Core.Domain.Product

  @product Product.new("P1", "Widget", Decimal.new("10.00"))

  @impl true
  def fetch("P1"), do: {:ok, @product}
  def fetch(_), do: {:error, :not_found}
end
