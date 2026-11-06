# Architecture

## Goals

1. **One source of truth.** Every fact (a farm's GGN, a variety's name, a retailer's code) is stored once.
2. **Work together without conflicts.** 7–8 technicians on the same network can edit at the same time.
3. **Know who did what.** Every row is stamped and every change is kept in history.
4. **Packhouses see only their data** and can't change the master directly.
5. **Don't break the labels.** The existing BarTender templates keep working, unchanged, during the switch.
6. **Many marketers, many seasons.** Capespan, Orex, Solar, Silverlands, Le Roux, Growers By Nature and others, each season rolling over cleanly.

## Pieces

### 1. Master database (SQL Server 2019 Express)

- Lives on the internal SQL Server (address kept in `.env`, never in the repository).
- Schemas:
  - `ref`: reference data (marketer, season, region, packhouse, farm, orchard, variety, pack, GTIN)
  - `label`: retailer-specific data (retailers, retailer codes, assortments, translations, output tables)
  - `ops`: change requests, imports, publish log
  - `sec`: application users and roles
- **Stamps** on every table: `CreatedBy`, `CreatedAt`, `ModifiedBy`, `ModifiedAt`, filled by the database from the Windows login (`ORIGINAL_LOGIN()`), so they can't be faked or forgotten.
- **History**: every table is a *system-versioned temporal table*. SQL Server keeps every earlier version of every row automatically, which answers "what did this look like last Tuesday, and who changed it?"
- **Conflict detection**: a `rowversion` column on every table. If two people edit the same record, the second save is refused with a clear message instead of silently overwriting.
- Express limits: 10 GB per database (label data is far below this). There's no SQL Agent, so scheduled jobs (backups, publishing) run through the Python sync tool and Windows Task Scheduler.

### 2. Technician screens (Microsoft Access front end)

- An `.accde` file on each technician's PC, linked to SQL Server over ODBC with Windows authentication. There are no separate passwords, and the Windows login *is* the identity.
- Forms for farms, orchards, varieties, GTINs, retailers and translations, with drop-downs instead of free typing.
- **Admin screen** (role `Admin`): add/disable technicians, see recent changes per person, view history, approve imports.
- **Inbox**: review packhouse change requests and approve or reject them.

### 3. Roles

| Role | Can |
|---|---|
| **Admin** | Everything: users, design changes, approvals, publishing |
| **Technician** | Edit master data, review change requests, publish |
| **Viewer** | Read only |

Roles are SQL Server database roles plus the `sec.AppUser` table (who is active, display name). Access to SQL Server itself is limited to the technical team.

### 4. Publishing (sync tool, grows out of `backup_manager`)

For each **packhouse** (marketer + season + region):

1. **Check** the data first. Every GTIN must be 14 digits with a valid check digit, every farm must have a PUC and GGN, no orchard can point to a missing variety, and every retailer table must have its required codes. If a check fails, nothing is published and the reason is listed.
2. **Build** a fresh `.accdb` containing only that packhouse's rows, with the **exact table and column names BarTender reads today** (see [bartender-table-mapping.md](bartender-table-mapping.md)).
3. **Deliver** it to the packhouse's Synology folder, but only if the print station isn't using the file (no `.laccdb` lock). If it's busy, leave the new copy beside it and try again later. Never replace a file mid-print.
4. **Log** what was sent, when, by whom, and a fingerprint of the file, so the system can later tell what the packhouse changed.

### 5. Packhouse change requests

1. The packhouse edits its copy (adds an orchard, fixes a spelling, even adds a column).
2. When the edited file syncs back, the sync tool compares it **row by row** with the copy that was published.
3. Every difference becomes a row in `ops.ChangeRequest`: new row, changed field (old → new), deleted row, or new column.
4. A technician approves or rejects each one. Approved changes are applied to the master, and the history shows *"requested by packhouse X, approved by technician Y"*.
5. The next publish sends the corrected copy back.

A new column from a packhouse is never added automatically. It's flagged for an Admin to decide.

### 6. Masterfile import

Paltrack masterfile batches (handled today by `paltrack_masterfile_builder.py`) are imported into `ref` tables as a **proposed change set**: *14 new GTINs, 2 farms changed GGN*. A technician approves it before it lands. Today this step is done by hand in Excel.

### 7. Backups

- A nightly full backup plus backups before every publish and import, run by the sync tool (`BACKUP DATABASE … WITH CHECKSUM`) and verified.
- Retention is configurable (e.g. 30 daily, 12 monthly).

## Rules we never break

- Nothing writes to a packhouse folder unless it passed the checks.
- No packhouse change reaches the master without a person approving it.
- A file that's open (locked) is never replaced.
- Real data, addresses and passwords never go into the repository.
- **During development, nothing touches the live Synology Drive.** All testing uses copies in a separate test folder.
