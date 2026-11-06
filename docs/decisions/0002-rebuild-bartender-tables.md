# 0002: Publish the exact tables BarTender already reads

**Context.** Dozens of BarTender templates read retailer-specific tables (`'Edeka G&G White$'`, `NA_ZA_Red$`, …) with odd names and columns (`Farm ` with a trailing space, `Cariety Group`). Redesigning every template at once is risky during the season.

**Decision.** SiteBase stores clean, normalised data, and at publish time **rebuilds every current table with identical names and columns** (`label.OutputTable` / `label.OutputColumn`).

**Consequences.** The switch-over needs no template changes. Tidying names happens later, one template at a time, by changing the output definition. The mapping must be kept accurate; see `docs/bartender-table-mapping.md`.
