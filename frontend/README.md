# Technician front end (Microsoft Access)

The screens technicians use to work on SiteBase. The Access file holds **no data**: it links to SQL Server and shows the data in simple screens. Only the VBA source is kept in Git (`src/`). The `.accdb` itself is git-ignored, because it is rebuilt from the source and would contain the real server address.

| File | What it does |
|---|---|
| `src/modSiteBaseConfig.example.bas` | Server, database and driver settings. Imported, then edited **inside Access only** |
| `src/modSiteBase.bas` | Everyday behaviour: login, navigation, search, filters, "Who changed this?", friendly error and conflict messages |
| `src/modSiteBaseBuild.bas` | Builds the front end: links the SQL tables and creates every screen |

## Screens

| Screen | Purpose |
|---|---|
| Log in | Personal SiteBase login + password. The password is never stored |
| Home | Shows who is logged in; buttons to every screen |
| Farms | PUC, name, PHC, GGN, GLN, FLO ID, country |
| Orchards | Farm (drop-down), season, orchard code, variety (drop-down), licences. Filter by farm |
| Varieties / Variety groups | Codes, short and long names, group and colour |
| Packs | Pack code, inner pack, net weight |
| GTINs | Search by GTIN |
| Data problems | Live list of everything that would block a publish |
| Admin *(admins only)* | Technicians list, recent changes by everyone |

Every data screen has **Refresh**, **Who changed this?** (full history of the selected row) and **Close**. Records are never deleted; untick **Active** instead. If two people save the same record, the second gets a clear message and **nothing is overwritten**.

## Building the front end (one time)

1. In Access: **File → New → Blank database**. Name it `SiteBase.accdb` and save it in `Desktop\SiteBase\frontend\`.
2. Press **Alt+F11** to open the VBA editor. **File → Import File…** and import the three files from `frontend\src\`, one at a time.
3. Double-click **modSiteBaseConfig** and change `SERVER-ADDRESS,1433` to the real server. Save (**Ctrl+S**).
4. **Debug → Compile**. If nothing happens, the code is fine.
5. Open the Immediate window (**Ctrl+G**), type `SB_BuildLoginForm` and press Enter.
6. Close the VBA editor. Open **frmLogin**, log in with your **admin** login, and answer **Yes** to "Build them now?".

To rebuild after a code change: re-import the changed module, open frmLogin, log in, then in the Immediate window run `SB_BuildAll`.

## Giving it to technicians

1. Each technician gets their own login: fill in and run `database/migrations/010_add_user_TEMPLATE.sql` (choose `SQL` as the login type, because the PCs are not on a domain).
2. While testing, the database is locked to its owner. Open it up with `ALTER DATABASE [SiteBase_Dev] SET MULTI_USER;`.
3. Copy `SiteBase.accdb` to each technician's PC. Each person works in their own copy of the front end; they all share the same data on the server.
