defmodule Cashier.Ports.Out.ProductCatalogue do
  @moduledoc """
  The contract for looking up products by code.

  Any module that implements `fetch/1` can serve as the product catalogue.
  The in-memory adapter ships by default, but you could swap in a database
  or API backed catalogue without touching the checkout logic.
  """

  alias Cashier.Core.Domain.Product

  @callback fetch(code :: String.t()) :: {:ok, Product.t()} | {:error, :not_found}
end
