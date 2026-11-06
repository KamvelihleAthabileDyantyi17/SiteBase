# Current BarTender tables → SiteBase

The print stations read the Capespan Access database (`CA_DBase_Access.accdb`) through a shared connection in the BarTender Administration Console.
SiteBase stores the data once, in clean tables, and **rebuilds every table below with exactly the same name and columns** when it publishes, so existing label templates keep working unchanged.

Snapshot of the NAM database taken on 6 Nov 2026: 47 tables, read-only copy. Row counts are for information only.

| Group | How SiteBase rebuilds it |
|---|---|
| Retired (5) | Not rebuilt. Old copy or paste leftover; archived during migration. |
| GTIN (2) | `ref.Gtin` (imported from Paltrack R2 GTIN export / masterfile builder), filtered by marketer and active flag. |
| Orchard label (14) | `label.vw_OrchardLabel` = Orchard × Farm × Variety × VarietyGroup, filtered by the retailer assortment and colour, plus that retailer's codes (`label.RetailerCode`) and translations. |
| Farm list (6) | `ref.Farm` (+ `label.RetailerCode` for retailer farm codes such as Edeka/Herstücke GTINs, + translations for origin/country lines). |
| Orchard list (4) | `ref.Orchard` (distinct orchard codes per farm / country; mix orchards flagged). |
| Variety list (4) | `ref.Variety` / `ref.VarietyGroup` / `ref.MixVariety` + `label.Translation`. |
| Pack (4) | `ref.Pack` (+ `label.RetailerCode` type PRODUCT_CODE for MO codes). |
| Fixed list / translation (8) | `label.Translation` or `label.RetailerCode` (small fixed lists per retailer). |

## Table by table

### Retired

| Access table | Rows | Columns |
|---|---:|---|
| `'Edeka G&G (2)$'OLD` | 306 | Farm, GGN, PUC, Variety Code, Variety Group, VG2, Variety, Orchard, GTIN, License 1, License 2, Country, CartonVG, Country2, Carton GTINS, Field1 |
| `'Edeka G&G Red-Black$' - Copy` | 160 | Farm, GGN, PUC, Variety Code, Variety Group, VG2, Variety, Orchard, GTIN, License 1, License 2, Country |
| `Paste Errors` | 304 | F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, F13, F14, F15, F16 |
| `'R2 Gtin Export - Grapes$'OLDMAIN` | 30,031 | GTIN, Orgzn, Commodity, Code, Pack, Grade, Mark, Inventory Code, Size Count, Start Date, End Date, Season, Country, Active, Tran User, Tran Date, Target Market, Target Market Active, Target Market Start Date, Target Market End Date, Target Market Tran User, Target Market Tran Date |
| `'R2 Gtin Export - Grapes$'OLD1` | 25,183 | GTIN, Orgzn, Commodity, Code, Pack, Grade, Mark, Inventory Code, Size Count, Start Date, End Date, Season, Country, Active, Tran User, Tran Date, Target Market, F18, Target Market Active, Target Market Start Date, Target Market End Date, Target Market Tran User, Target Market Tran Date, F24 |

### GTIN

| Access table | Rows | Columns |
|---|---:|---|
| `'R2 Gtin Export - Grapes$'` | 6,407 | GTIN, Orgzn, Commodity, Code, VARIETY GROUP CODE, Pack, Grade, Mark, Inventory Code, Size Count, Country, Target Market |
| `R2 Gtin Export - Grapes_MX$` | 20,735 | GTIN, Orgzn, Commodity, Code, VARIETY GROUP CODE, Pack, Grade, Mark, Inventory Code, Size Count, Country, Target Market |

### Orchard label

| Access table | Rows | Columns |
|---|---:|---|
| `NA_ZA_White$` | 141 | Farm, GGN, PUC, Code, Variety Group, Variety, Orchards, License 1, License 2 |
| `NA_ZA_Red$` | 139 | Farm, GGN, PUC, Code, Variety Group, Variety, Orchards, Origin, License 1, License 2 |
| `NA_ZA_Black$` | 26 | Farm, GGN, PUC, Code, Variety Group, Variety, Orchards, License 1, License 2 |
| `NA_ZA_Red_Black$` | 165 | GGN, PUC, Code, Variety Group, Variety, Orchards, Field1, License 1, License 2 |
| `NA_ZA_Orchards$` | 306 | Farm, GGN, PUC, Code, Variety Group, Variety, Orchards, Country, License 1, License 2 |
| `NA_ZA_Netto$` | 306 | Farm, GGN, PUC, Code, Variety Group, Variety Group2, Variety, Orchards, Country, License 1, Netto GTIN, License 2 |
| `NA_ZA_Mamba$` | 306 | Farm, GGN, PUC, Variety Code, Variety Group, VG2, VG3, Variety, Orchard, GTIN, License 1, License 2, Country |
| `'Edeka G&G White$'` | 143 | Farm, GGN, PUC, Variety Code, Variety Group, VG2, Variety, Orchard, GTIN, License 1, License 2, Country |
| `'Edeka G&G Red-Black$'` | 160 | Farm, GGN, PUC, Variety Code, Variety Group, VG2, Variety, Orchard, GTIN, License 1, License 2, Country |
| `'Edeka G&G (2)$'` | 306 | Farm, GGN, PUC, Variety Code, Variety Group, VG2, Variety, Orchard, GTIN, License 1, License 2, Carton GTINS, Carton VG, Country, Country2, Herstucke 45kg |
| `'ALL Sanlu 10x500$'` | 303 | Farm, Packhouse, Address, GGN, PUC, Code, Variety Group, Variety, Orchard, License 1, License 2, GRLuxembourgish, GRCroatian, GRCzech, GRRomanian, GRSlovak, GRBulgarian, GRPolish, GREnglish, ORLuxembourgish, ORCroatian, ORCzech, ORRomanian, ORSlovak, ORBulgarian, ORPolish, OREnglish |
| `SanLu4#5$` | 184 | Farm, GGN, PUC, Code, Variety Group, VG2, Variety, Orchard, EAN1, EAN2, Caliber, Weight, TM, Country, Produce, F16, F17, F18, F19 |
| `'SanLucar PLBag$'` | 178 | Farm, GGN, PUC, Code, Cariety Group, VG2, Variety, Orchard, PL-Bag, Carton EAN13 Name, Carton EAN13, Carton Code128 Name, Carton Code128, Country, Produce |
| `Kaufland_Germany_excl_mix$` | 303 | Variety, PUC, Farm, GGN, Code, Variety Group, Orchards, License 1, License 2, VG German, VG Czech, VG Croation, VG Polish, VG Romanian, VG Bulgarian, VG Slovak, VG English |

### Farm list

| Access table | Rows | Columns |
|---|---:|---|
| `PHC$` | 9 | Farm, Country, PHC, PUC, Country2 |
| `Lidl_PHC$` | 9 | Farm, Origin, GR_Code, PHC |
| `Lidl_Farm_NA_ZA$` | 9 | Packhouse, PUC, PHC, GGN, Country, A1, A2, A3, A4, A5, A6, Origin, GR_Code |
| `Kaufland_Origin$` | 10 | Farm, GGN, PUC, PHC, Country, Country2, Country3, Country4, Flo_ID, Address, Country6, Edeka_GTIN, Country7, PUC_Name, Flo |
| `Farm_List_Kaufland_Germany$` | 9 | Farm, PUC, PHC, Country, Address, Country_Rewe, Country_German, Country_Czech, Country_Croation, Country_Polish, Country_Romanian, Country_Bulgarian, Country_Slovak, Country_English, GGN |
| `NA_ZA_PUC3$` | 10 | GGN, Farm, Country, PUC, PHC, Herstücket GTIN |

### Orchard list

| Access table | Rows | Columns |
|---|---:|---|
| `NA_ZA_PUC$` | 170 | Orchards, Country, PUC |
| `NA_ZA_PUC2$` | 170 | Orchards |
| `Mix_Orchards$` | 170 | Orchards |
| `NA_ZA_PUC_MIX$` | 170 | Country, Orchards |

### Variety list

| Access table | Rows | Columns |
|---|---:|---|
| `Aldi_Hofer_CTN$` | 121 | Code, Variety Group, Variety, Variety Group Translation |
| `'Saudi VG$'` | 86 | Variety Group Eng, Code, Variety Group Ara, Variety G(roup, Variety |
| `'MIX CODE$'` | 74 | Code, VARIETY GROUP, VARIETY GROUP 1, VARIETY A, VARIETY B, VARIETY, L1, L2 |
| `'Herstücke_MIX$'` | 73 | Code, VARIETY GROUP, VARIETY GROUP 1, VARIETY A, VARIETY B, VARIETY, Carton VG, Punnet GTIN ZA, Punnet GTIN NA, Carton GTIN ZA, Carton GTIN NA |

### Pack

| Access table | Rows | Columns |
|---|---:|---|
| `'Pack code$'` | 40 | Pack Code, Pack, Inner Pack, Nett Weight |
| `'Pack code Netto$'` | 2 | Pack Code, Pack, Inner Pack, Nett Weight |
| `MO$` | 9 | Pack, Variety Group, MO Header, MO Product Code |
| `MO_new$` | 10 | Pack, Variety Group, MO Header, MO Product Code, MO Pack |

### Fixed list / translation

| Access table | Rows | Columns |
|---|---:|---|
| `'Saudi BrandMark$'` | 3 | Brand/Mark Eng, Brand/Mark Ara |
| `'Saudi Count$'` | 4 | Count Eng, Count Ara |
| `'Saudi Origin$'` | 2 | Origin Eng, Origin Ara |
| `'Asia Specs$'` | 2 | Country, Line 1, Line 2 |
| `Lidl_Codes$` | 7 | Lidl Code, IAN Code, Nett Weight, Translations |
| `Netto_Mark/Brand` | 2 | Target Market |
| `Netto_Size_Count` | 4 | Size/Count |
| `Carton_Target_Market` | 139 | Target Market |

## Known column-name problems to keep (for now) or fix later

These are reproduced exactly when publishing, so templates don't break. They're cleaned up template by template in a later stage.

- `Farm ` (trailing space) in the Edeka tables
- `Cariety Group` in `'SanLucar PLBag$'`
- `Variety G(roup` and `Variety Group Eng ` in `'Saudi VG$'`
- `VARIETY ` (trailing space) in `'MIX CODE$'`
- Empty spill-over columns `F16`–`F19` in `SanLu4#5$`, `Field1` in `NA_ZA_Red_Black$`
- Table names carry Excel sheet suffixes (`$`) and quotes from the original Excel import
