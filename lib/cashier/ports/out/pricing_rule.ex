defprotocol Cashier.Ports.Out.PricingRule do
  @moduledoc """
  The contract every pricing rule must satisfy.

  Implement `applies_to?/2` to declare which product code the rule
  covers, and `calculate/3` to return the line total for a given
  quantity and unit price. The result must be a `Decimal` rounded
  to 2 decimal places, the checkout trusts this and won't re-round
  individual line totals.

  Because this is a protocol, adding a new promotion is just defining
  a new struct and its implementation, no existing code changes.
  """

  @doc "Returns true if the rule applies to the given product code."
  @spec applies_to?(t(), String.t()) :: boolean()
  def applies_to?(rule, product_code)

  @doc "Returns the total price for `quantity` units at `unit_price`, rounded to 2 decimal places."
  @spec calculate(t(), pos_integer(), Decimal.t()) :: Decimal.t()
  def calculate(rule, quantity, unit_price)
end
