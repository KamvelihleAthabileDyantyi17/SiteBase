# Database migrations

Numbered SQL scripts that build SiteBase on SQL Server 2019. Run them **in order**. Each one is safe to run again: it skips anything that already exists.

| Script | What it does |
|---|---|
| `001_create_database.sql` | Creates the **SiteBase_Dev** database (touches nothing else) |
| `002_schemas_roles_functions.sql` | Schemas `ref`, `label`, `ops`, `sec`; roles Admin/Technician/Viewer; "current user" and GS1 check-digit functions |
| `003_ref_tables.sql` | Farms, orchards, varieties, packs, GTINs … *(generated)* |
| `004_label_tables.sql` | Retailers, retailer codes, assortments, translations, output tables *(generated)* |
| `005_ops_sec_tables.sql` | Imports, publish log, change requests, checks, users *(generated)* |
| `006_stamp_triggers.sql` | Fills Created/Modified By/At on every save *(generated)* |
| `007_checks_and_views.sql` | `ops.vw_DataProblems` (pre-publish checks), `ref.vw_OrchardDetail` |
| `008_permissions.sql` | What each role may do |
| `009_lookup_data.sql` | Fixed lists: commodity, languages, retailer code types |
| `011_views_for_screens.sql` | Views the technician screens use (recent changes) |
| `010_add_user_TEMPLATE.sql` | **Not part of the build.** Copy and fill in to give a person access; refuses to run until filled in |

Scripts marked *generated* come from `database/tools/generate_migrations.py`. To change a table, edit the generator and re-run it (`python database/tools/generate_migrations.py`), then commit both.

## Running them (SQL Server Management Studio)

1. Open SSMS and connect to the SQL Server with **Windows Authentication**. You need rights to create a database.
2. **File → Open → File…**, open `001_create_database.sql`, press **F5**. The Messages tab should end with *"SiteBase_Dev is ready."*
3. Do the same for `002` … `009` and `011`, in order. (Skip `010`; it is only for adding people later.) Each ends with a "ready" or "granted" message, or with no errors.
4. Load test data: open `local/seed_capespan_test.sql` (not in Git) and press **F5**. You get two result grids: row counts per table, and the data problems found.

## Try it

```sql
USE SiteBase_Dev;

-- Everything a label needs, one row per orchard
SELECT TOP 20 * FROM ref.vw_OrchardDetail ORDER BY PUC, OrchardCode;

-- Make a change...
UPDATE ref.Farm SET Name = N'Arendsnes' WHERE PUC = 'A0301';

-- ...see who made it and when
SELECT PUC, Name, CreatedBy, CreatedAt, ModifiedBy, ModifiedAt FROM ref.Farm WHERE PUC = 'A0301';

-- ...and the full history (every earlier version is kept automatically)
SELECT PUC, Name, ModifiedBy, ValidFrom, ValidTo
  FROM ref.Farm FOR SYSTEM_TIME ALL
 WHERE PUC = 'A0301'
 ORDER BY ValidFrom;

-- What would block a publish right now?
SELECT * FROM ops.vw_DataProblems ORDER BY Severity, RuleCode;
```

Times are stored in UTC (South Africa is UTC+2).

## Starting over (development only)

```sql
USE master;
ALTER DATABASE SiteBase_Dev SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE SiteBase_Dev;
```
Then run 001–009 again. **Never** do this on a production database.
