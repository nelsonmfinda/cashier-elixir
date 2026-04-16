# Cashier Service Specification

## Project Overview
- **Project name:** Cashier
- **Type:** Elixir library/service
- **Purpose:** Manage shopping carts, apply pricing rules, compute totals
- **Target users:** Supermarket checkout systems

## Requirements

### Test Products
| Code | Name | Price |
|------|------|-------|
| GR1 | Green tea | £3.11 |
| SR1 | Strawberries | £5.00 |
| CF1 | Coffee | £11.23 |

### Pricing Rules
1. **BOGO (Buy One Get One Free):** Every 2nd Green Tea free
2. **Bulk Fixed:** 3+ strawberries at £4.50 each
3. **Bulk Fraction:** 3+ coffees at 2/3 price

### Expected Basket Totals
| Basket | Expected Total |
|-------|----------------|
| GR1,SR1,GR1,GR1,CF1 | £22.45 |
| GR1,GR1 | £3.11 |
| SR1,SR1,GR1,SR1 | £16.61 |
| GR1,CF1,SR1,CF1,CF1 | £30.57 |

## Architecture
- Hexagonal (Ports & Adapters)
- Domain: Cart, CartItem, Product
- Ports: ProductCatalogue, PricingRule
- Adapters: InMemoryCatalogue, PricingRules
- Session: GenServer per checkout

## API
- `new_checkout()` → Session
- `scan(Session, code)` → :ok
- `total(Session)` → Decimal
- `formatted_total(Session)` → "£XX.XX"
- `clear(Session)` → :ok
- `stop(Session)` → :ok

## Validation
- Product codes: 1-32 bytes
- Prices: non-negative, max £999,999.99
- Rules validated at startup
- Quantity: non-negative

## Testing
- Unit tests for domain
- Unit tests for rules
- Property-based tests (StreamData)
- Integration via Cashier module

## Acceptance Criteria
1. All expected basket totals pass
2. Empty cart returns £0.00
3. Zero quantity handled gracefully
4. Duplicate rules rejected at startup
5. Session auto-expires after idle