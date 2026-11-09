# Build log

A step-by-step record of how SiteBase was built: what was done, why, and proof that it worked (screenshots). One page per stage.

| Stage | Page | Status |
|---|---|---|
| 0: Design | [Design documents](../architecture.md) | Done |
| 1: Master database | [stage-1-database.md](stage-1-database.md) | Done |
| 2: Technician screens | [stage-2-screens.md](stage-2-screens.md) | In progress |

## How screenshots are taken and stored

- Windows: **Win + Shift + S**, drag around the area, then paste into Paint (or click the notification) and save as **PNG**.
- Save into `docs/build-log/images/stage-<n>/` using the **exact file name** given in that stage's page, e.g. `images/stage-1/01-database-created.png`.
- Crop to what matters (the Object Explorer tree, the Messages tab, the result grid). Avoid full-screen shots.

## Before saving a screenshot, check it does NOT show

- **Passwords** (including in a script tab)
- The **server IP address** (crop it out, or blur it in Paint with a filled rectangle)
- **Client data**: farm names, GGNs, PUCs, GTINs, customer names. Show row *counts* and table *structure*, not the rows. For a "data" screenshot, use a query that shows counts, or blur the values.

The repository is private now, but it may become public for a portfolio later. Screenshots are hard to clean up afterwards.

## Commit messages

```
Stage 1: <what was done, in a few words>

- <detail>
- <detail>
```

Examples:
- `Stage 1: create SiteBase_Dev and lock it to owner`
- `Stage 1: build tables, history and stamps (scripts 002-009)`
- `Stage 1: load Capespan test data, record results`
- `Docs: build log screenshots for stage 1`

One commit per meaningful step, so the GitHub history reads like a diary of the build.
