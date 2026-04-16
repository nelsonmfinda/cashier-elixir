# Cashier

[![CI](https://github.com/nelsonmfinda/cashier-elixir/actions/workflows/ci.yml/badge.svg)](https://github.com/nelsonmfinda/cashier-elixir/actions/workflows/ci.yml)
[![Coverage Status](https://coveralls.io/repos/github/nelsonmfinda/cashier-elixir/badge.svg?branch=main)](https://coveralls.io/github/nelsonmfinda/cashier-elixir?branch=main)

A checkout service built in Elixir. Scan products, apply
promotions, and get the total, all with exact `Decimal` arithmetic.

## Products and pricing rules

| Code | Product      | Price  | Promotion                                      |
|------|--------------|--------|-------------------------------------------------|
| GR1  | Green tea    | £3.11  | Buy one get one free                            |
| SR1  | Strawberries | £5.00  | Buy 3 or more, price drops to £4.50 each        |
| CF1  | Coffee       | £11.23 | Buy 3 or more, price drops to 2/3 of original   |

### Expected totals

| Basket                    | Total  |
|---------------------------|--------|
| GR1, SR1, GR1, GR1, CF1  | £22.45 |
| GR1, GR1                 | £3.11  |
| SR1, SR1, GR1, SR1       | £16.61 |
| GR1, CF1, SR1, CF1, CF1  | £30.57 |

## Quick start

```bash
mix setup
mix test
```

## Documentation

Run `mix docs` to generate HTML documentation at `doc/index.html`.

## Try it in IEx

```elixir
iex -S mix

{:ok, session} = Cashier.new_checkout()
Cashier.scan(session, "GR1")
Cashier.scan(session, "GR1")
Cashier.scan(session, "SR1")
Cashier.formatted_total(session)
#=> "£8.11"

# Clear and start over
Cashier.clear(session)
Cashier.formatted_total(session)
#=> "£0.00"

# Stop the session when done
Cashier.stop(session)
```

## Running with Docker

Build the test image:

```bash
docker build --target test -t cashier-test .
```

Start an interactive session:

```bash
docker run --rm -it cashier-test iex -S mix
```

Then try the checkout directly in IEx:

```elixir
{:ok, checkout} = Cashier.new_checkout()

Cashier.scan(checkout, "GR1")
Cashier.scan(checkout, "CF1")
Cashier.scan(checkout, "GR1")

Cashier.formatted_total(checkout)
#=> "£14.34"
```

Available products:

| Code | Name         | Price  |
|------|--------------|--------|
| GR1  | Green tea    | £3.11  |
| SR1  | Strawberries | £5.00  |
| CF1  | Coffee       | £11.23 |

#### Run tests

```bash
docker run --rm cashier-test mix test
```

#### Run quality checks

```bash
docker run --rm cashier-test mix credo --strict
docker run --rm cashier-test mix dialyzer
```

## Quality checks

```bash
mix compile --warnings-as-errors
mix format --check-formatted
mix credo --strict
mix dialyzer
```

Git hooks run these automatically `pre-commit` runs compile, format,
credo, and tests. `pre-push` runs dialyzer.

## Adding a new pricing rule

1. Define a struct and implement the `PricingRule` protocol:

```elixir
defmodule Cashier.Adapters.Rules.BuyThreePayTwo do
  defstruct [:product_code]

  defimpl Cashier.Ports.Out.PricingRule do
    def applies_to?(%{product_code: code}, code), do: true
    def applies_to?(_rule, _code), do: false

    def calculate(_rule, quantity, unit_price) when quantity > 0 do
      free = div(quantity, 3)

      Decimal.new(quantity - free)
      |> Decimal.mult(unit_price)
      |> Decimal.round(2)
    end
  end
end
```

2. Pass it when creating a session:

```elixir
rule = %Cashier.Adapters.Rules.BuyThreePayTwo{product_code: "JC1"}
{:ok, session} = Cashier.new_checkout(pricing_rules: [rule | Cashier.Defaults.pricing_rules()])
```

No existing files need to change.

## Architecture

```txt
lib/cashier/
├── core/
│   ├── domain/          Product, Cart, CartItem — plain data, no deps
│   └── use_cases/       Checkout — scanning + totalling, pure functions
├── ports/out/           PricingRule (protocol), ProductCatalogue (behaviour)
├── adapters/
│   ├── db/in_memory/    Compile-time product map
│   └── rules/           BOGO, bulk fixed, bulk fraction
├── checkout_session.ex  GenServer per session, registered in Registry
├── defaults.ex          Default catalogue + rules (business config)
├── price_formatter.ex   Formatting
└── session.ex           Opaque session handle
```
