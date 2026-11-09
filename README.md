# SiteBase

**One clean, audited source for the data behind fruit-export labels.**

SiteBase holds the master data that BarTender print stations use to print packhouse labels: farms (PUC, GGN, GLN), orchards, varieties, packs, GTINs, retailers and their translations. Technicians edit the data together on SQL Server, and every change is stamped with who made it and when. Each packhouse gets a checked copy containing only its own data. When a packhouse changes its copy, the changes arrive as requests for a technician to approve. Nothing is pushed straight through.

> Status: **Stage 1 complete:** `SiteBase_Dev` built on SQL Server 2019 with stamps, history, roles, checks and a test data set. **Next: Stage 2, technician screens.** See [docs/roadmap.md](docs/roadmap.md) and [database/migrations](database/migrations/README.md).

---

## Why

Today each marketer's label data lives in an Access database built from pasted Excel sheets. One table per retailer label repeats the same farm, variety and orchard details, so:

- one farm change means editing up to **22 tables**, and the copies drift apart (the same farm under three spellings, 65 variety codes with more than one spelling);
- copies of the file are synced around with Synology Drive, which creates conflict copies and lets one person's changes overwrite another's;
- there is no record of who changed what.

SiteBase stores each fact **once**, lets 7–8 technicians work at the same time without overwriting each other, keeps a full history, and still produces the **exact tables the existing BarTender templates read**, so no label has to be redesigned to switch over.

## How it works

```
 Paltrack masterfiles (GTINs, farms, varieties …)
          │  import, review differences, approve
          ▼
 ┌──────────────────────────────────────────────┐
 │  SiteBase master: SQL Server 2019            │
 │  clean tables · CreatedBy/ModifiedBy stamps  │
 │  full change history (temporal tables)       │
 │  roles: Admin · Technician · Viewer          │
 └───────▲──────────────────────────┬───────────┘
         │ edit at the same time     │ publish: checks first, then
         │ (Access screens,          │ rebuild the BarTender tables,
         │  Windows login = name)    │ one copy per packhouse
 ┌───────┴────────────┐      ┌───────▼───────────────────────────┐
 │ Technicians        │      │ Packhouse copy (.accdb)            │
 │ (same network)     │      │  → Synology Drive                  │
 └────────────────────┘      │  → BarTender Print Station         │
                             └───────┬───────────────────────────┘
                                     │ packhouse edits its copy
                                     ▼
                       Change Requests inbox → technician approves → master
```

Full detail: [docs/architecture.md](docs/architecture.md).

## Repository layout

| Folder | Contents |
|---|---|
| `docs/` | Architecture, data model, BarTender table mapping, roadmap |
| `docs/decisions/` | Decision records: what we chose and why |
| `docs/build-log/` | Step-by-step record of the build, with screenshots |
| `database/migrations/` | SQL scripts that build the SiteBase database, in order *(Stage 1)* |
| `frontend/` | Technician Access screens, exported as text *(Stage 2)* |
| `sync/` | Publishing, change-request collection and backups; grows out of `backup_manager` *(Stage 3–5)* |
| `scripts/` | Double-click `.bat` launchers |
| `local/` | **Never committed.** Real data, snapshots, working notes |

## Tech

- **SQL Server 2019 Express**: master database, row-level concurrency, temporal tables for history
- **Microsoft Access**: technician screens and the published packhouse copies
- **BarTender** (Administration Console shared connection): reads the published copies at print stations
- **Python 3**: import, publish, change-request collection, backups
- **Synology Drive**: delivers each packhouse's copy (and brings their edits back)

## Data and security

This repository contains **no client data, server addresses or passwords**. Real configuration lives in `config.json` and `.env` (both git-ignored); see `config.example.json`. Anything under `local/` is ignored.

---

Built by Kamvelihle Dyantyi.
