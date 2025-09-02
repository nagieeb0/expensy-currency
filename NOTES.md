# NOTES.md (LiveView + Ecto)

=> Money/Currency Handling Approach

-   Used `:decimal` with the `Decimal` library for all financial values
    (categories and expenses).
-   Avoided floats entirely to prevent rounding errors.
-   In forms, used `step="0.01"` to enforce 2‑decimal precision for
    money fields.
-   Multi-currency extension plan:
    -   Add a `currency` column (ISO code) to categories/expenses.
    -   Enforce validation against supported currencies.
    -   Add exchange rates table (or external API) for cross-currency
        calculations.
    -   Aggregate calculations per currency, not mixed.

=> Architectural Decisions

-   Context: `Finance` (a.k.a. `Wallet`) created to group categories and
    expenses.
-   Business logic (validations, totals) lives in context functions,
    while LiveView handles UI and state.
-   LiveView chosen for real-time updates: adding an expense updates
    totals instantly.
-   Ecto schemas used directly with changesets for validation +
    constraints.

=> Trade-offs & Shortcuts

-   Advanced styling (Tailwind basic).
-   Pagination skipped for simplicity , Will be implemented if we have more data
-   Some DB constraints could be expanded (unique category names, budget
    upper bounds).

=> Testing Strategy

-   Schema tests: ensured validations for required fields, numerical
    constraints, positive amounts.
-   LiveView tests: validated adding expenses updates totals
    instantly.
-   Workflow tests: category creation → expense addition → progress
    calculation.
-   Still room to expand with integration tests for edge cases
    (multi-currency, budget overflow).

=> UI

-   Used Tailwind CSS & DaisyUI for better representation of data




=> Next Steps

1.  Add DB‑level constraints for extra safety.
4.  Add pagination for large datasets.

------------------------------------------------------------------------

Summary: Correct financial handling with Decimals, strong LiveView
real-time UI, and Ecto schemas for clarity. Multi-currency can be
layered with currency codes and exchange rate support.
