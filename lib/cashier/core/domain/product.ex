defmodule Cashier.Core.Domain.Product do
  @moduledoc """
  A product with a code, a name, and a price.

  This is a plain data struct with no behaviour attached, just the
  facts about a product that the rest of the system needs.

  ## Example

      iex> Cashier.Core.Domain.Product.new("GR1", "Green tea", Decimal.new("3.11"))
      %Cashier.Core.Domain.Product{code: "GR1", name: "Green tea", price: Decimal.new("3.11")}
  """

  @max_price Decimal.new("999999.99")

  @enforce_keys [:code, :name, :price]
  defstruct [:code, :name, :price]

  @type t :: %__MODULE__{
          code: String.t(),
          name: String.t(),
          price: Decimal.t()
        }

  @spec new(String.t(), String.t(), Decimal.t()) :: t()
  def new(code, name, %Decimal{} = price)
      when is_binary(code) and byte_size(code) > 0 and
             is_binary(name) and byte_size(name) > 0 do
    if Decimal.negative?(price) do
      raise ArgumentError,
            "price must be non-negative, got: #{Decimal.to_string(price)}"
    end

    if Decimal.compare(price, @max_price) == :gt do
      raise ArgumentError,
            "price exceeds maximum allowed value of #{Decimal.to_string(@max_price)}"
    end

    %__MODULE__{code: code, name: name, price: price}
  end
end
