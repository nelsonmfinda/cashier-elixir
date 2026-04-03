defmodule Cashier.Session do
  @moduledoc """
  A handle you get back when starting a checkout session.

  Pass it to `Cashier.scan/2`, `Cashier.total/1`, etc. You never need
  to look inside it, the struct hides how sessions are tracked internally.
  """

  @enforce_keys [:id]
  defstruct [:id]

  @type t :: %__MODULE__{id: String.t()}
end
