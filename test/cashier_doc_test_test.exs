defmodule Cashier.DocTestTest do
  use ExUnit.Case, async: true
  doctest Cashier.PriceFormatter
  doctest Cashier.Core.Domain.Product
  doctest Cashier.Core.Domain.Cart
end
