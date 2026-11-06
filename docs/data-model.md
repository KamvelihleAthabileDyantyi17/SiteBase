# Data model (draft, Stage 0)

Every table also has the standard columns: `CreatedBy`, `CreatedAt`, `ModifiedBy`, `ModifiedAt`, `RowVer` (rowversion), and system-versioning period columns (`ValidFrom`, `ValidTo`) with a matching `…History` table.

Naming: singular `PascalCase` table names, `…ID` integer surrogate keys, business codes kept as their own unique columns (`PUC`, `GTIN`, `VarietyCode`).

## `ref`: reference data

| Table | Key columns | Notes |
|---|---|---|
| **Marketer** | MarketerID, MarketerCode (`CA`), Name | Capespan, Orex, Solar … The Paltrack `Orgzn` code |
| **Season** | SeasonID, SeasonCode (`26-27`), StartDate, EndDate | Seasons roll over without copying folders |
| **Region** | RegionID, RegionCode (`NAM`, `WC`, `SA`), Name, CountryCode | |
| **Packhouse** | PackhouseID, MarketerID, RegionID, PHC, Name, Address, PublishFolder, IsActive | One published copy per packhouse per season |
| **Farm** | FarmID, MarketerID, PUC, Name, PHC, GGN, GLN, FloID, CountryCode, Address, RegionID | GGN 13 digits; GLN 13 digits with check digit |
| **Orchard** | OrchardID, FarmID, SeasonID, OrchardCode, VarietyID, Licence1, Licence2, IsMixOrchard | Licences = plant-breeder licence numbers |
| **Commodity** | CommodityCode (`GR`), Name | |
| **VarietyGroup** | VarietyGroupID, CommodityCode, VarietyGroupCode (`RS`), Name (`RED SEEDLESS`), Colour (White/Red/Black) | Colour drives the White/Red/Black label tables |
| **Variety** | VarietyID, CommodityCode, VarietyCode (`I68`), Name (`IFG 68-175`), LongName (`IFG 68-175 (SWEET CELEBRATION™)`), VarietyGroupID | One spelling, one place |
| **MixVariety** | VarietyID (the mix code), VarietyA_ID, VarietyB_ID, DisplayName | From `MIX CODE$` / `Herstücke_MIX$` |
| **Pack** | PackCode (`A03D`), InnerPack (`10x300g`), NetWeight | |
| **TargetMarket** | TargetMarketCode, Name | From Paltrack |
| **Gtin** | GTIN (14 digits), MarketerID, CommodityCode, VarietyCode, VarietyGroupCode, PackCode, Grade, Mark, InventoryCode, SizeCount, CountryCode, IsActive | Imported from R2 GTIN export / masterfile builder |
| **GtinTargetMarket** | GTIN, TargetMarketCode, IsActive | A GTIN can serve several markets |

## `label`: retailer-specific data

| Table | Key columns | Notes |
|---|---|---|
| **Retailer** | RetailerID, MarketerID, Name (`Edeka`), Programme (`G&G`), ImporterName, ImporterAddress, LotCodeRule | Lot code meaning differs per retailer: batch no., packing month or a code |
| **RetailerCode** | RetailerCodeID, RetailerID, CodeType, scope columns (FarmID, VarietyID, VarietyGroupID, PackCode, CountryCode, all optional), Value | Edeka/Netto GTINs, Lidl IAN, SanLucar EAN1/EAN2/PL-bag/Code128, MO product codes, Herstücke GTINs |
| **RetailerAssortment** | RetailerID, OrchardID (or FarmID + VarietyID), IsIncluded | Which farms/varieties appear on which retailer's label (e.g. *Kaufland Germany excl. mix*) |
| **Language** | LanguageCode (`de`, `cs`, `hr`, `pl`, `ro`, `bg`, `sk`, `lb`, `en`, `ar`, `fr`, `ru`), Name | |
| **Translation** | EntityType (VarietyGroup / Origin / Grade / Count / BrandMark / Country), EntityKey, LanguageCode, RetailerID (optional), Text | Replaces the `VG German`, `ORCzech`, `Saudi VG` … columns |
| **OutputTable** | OutputTableID, MarketerID, RegionID, AccessTableName (`'Edeka G&G White$'`), ViewName, IsActive | The list of tables a publish must produce, and which view builds each |
| **OutputColumn** | OutputTableID, Ordinal, AccessColumnName (`Farm ` with its trailing space), SourceExpression | Column names reproduced exactly as BarTender expects |

## `ops`: operations

| Table | Purpose |
|---|---|
| **ImportBatch** / **ImportChange** | A masterfile import shown as proposed changes, approved or rejected |
| **PublishLog** | Each copy sent: packhouse, file fingerprint, row counts, who, when, result |
| **ChangeRequest** | One row per packhouse change: packhouse, table, record key, field, old value, new value, type (Insert/Update/Delete/NewColumn), status, reviewed by/at, comment |
| **ValidationResult** | Results of the pre-publish checks |

## `sec`: security

| Table | Purpose |
|---|---|
| **AppUser** | WindowsLogin (`DOMAIN\name`), DisplayName, Role, IsActive, LastSeenAt |

## Example: how `'Edeka G&G White$'` is rebuilt

```
Orchard ⨝ Farm ⨝ Variety ⨝ VarietyGroup (Colour = White)
  ⨝ RetailerAssortment (Retailer = Edeka G&G)
  ⨝ RetailerCode (Edeka GTIN for that variety group/pack)
  ⨝ Translation (VG2 = variety group in German: "Hell")
→ columns: Farm , GGN, PUC, Variety Code, Variety Group, VG2, Variety, Orchard, GTIN, License 1, License 2, Country
```

## Open questions

- Is the **lot code** (`L-…`) printed from the database for any retailer, or always typed or derived at print time?
- Do orchards change per season (re-numbering), or carry over?
- Which retailer codes depend on pack or size as well as variety group?
