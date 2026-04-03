defmodule Cashier.PriceFormatter do
  @moduledoc """
  Turns a `Decimal` price into a display string like `"£22.45"`.
  """

  @doc ~S"""
  Formats a Decimal price with the pound symbol.

  ## Example

      iex> Cashier.PriceFormatter.format(Decimal.new("22.45"))
      "£22.45"
  """
  @spec format(Decimal.t()) :: String.t()
  def format(%Decimal{} = price), do: "£#{Decimal.to_string(price)}"
end
