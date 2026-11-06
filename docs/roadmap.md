# Roadmap

| Stage | What | Done when |
|---|---|---|
| **0: Design** | Study the current Capespan database, agree the data model, set up this repository | Design reviewed and agreed |
| **1: Master database** | SQL scripts: schemas, tables, stamps, history, roles. Load a **test copy** of Capespan's data and clean it up (spellings, duplicates) | SiteBase database exists on the test server with clean Capespan data |
| **2: Technician screens** | Access front end linked to SQL Server; admin screen; conflict messages | Two technicians can edit at the same time, and history shows who did what |
| **3: Publishing** | Checks + rebuild the BarTender tables per packhouse into a **test folder** | A published copy prints correctly in BarTender (on a test template), and its tables are identical in shape to today's |
| **4: Change requests** | Compare a returned copy with what was sent, inbox, approve/reject | A packhouse edit arrives as a request and an approval flows back out |
| **5: Imports, backups, scheduling** | Paltrack masterfile import with review, automated backups, `.bat` launchers, Task Scheduler | Runs unattended |
| **6: Pilot on Synology** | One packhouse, one marketer, live, with the old database kept as a fallback | A full week of labels printed from SiteBase |
| **7: Roll out** | Other marketers (Orex, Solar, Silverlands, Le Roux, Growers By Nature …) | All marketers on SiteBase |

**Rule for stages 0–5:** nothing touches the live Synology Drive. All testing uses copies.
