"""
Generates the SiteBase table migrations from one table specification, so every
table gets identical stamps, history and triggers.

    python database/tools/generate_migrations.py

Writes database/migrations/003_ref_tables.sql ... 006_stamp_triggers.sql.
Edit TABLES below, not the generated .sql files.
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "migrations")
DB = "SiteBase_Dev"

# Column: (name, type, null?, extra)   extra = DEFAULT / CHECK / IDENTITY text
# Table:  schema, name, columns, pk, uniques, fks, checks, temporal
def T(schema, name, cols, pk, uniques=(), fks=(), checks=(), temporal=True, doc=""):
    return dict(schema=schema, name=name, cols=cols, pk=pk, uniques=uniques,
                fks=fks, checks=checks, temporal=temporal, doc=doc)

ID = "INT IDENTITY(1,1)"
ACTIVE = ("IsActive", "BIT", False, "DEFAULT (1)")
DIGITS13 = "{c} IS NULL OR ({c} NOT LIKE '%[^0-9]%' AND LEN({c}) = 13)"

TABLES = [
    # ---------------------------------------------------------------- ref
    T("ref", "Marketer", [
        ("MarketerID", ID, False, ""), ("MarketerCode", "VARCHAR(4)", False, ""),
        ("Name", "NVARCHAR(100)", False, ""), ACTIVE],
        ["MarketerID"], uniques=[["MarketerCode"]],
        doc="Capespan, Orex, Solar ... MarketerCode = Paltrack Orgzn (e.g. CA)."),
    T("ref", "Season", [
        ("SeasonID", ID, False, ""), ("SeasonCode", "VARCHAR(10)", False, ""),
        ("StartDate", "DATE", True, ""), ("EndDate", "DATE", True, ""),
        ("IsCurrent", "BIT", False, "DEFAULT (0)")],
        ["SeasonID"], uniques=[["SeasonCode"]],
        checks=["EndDate IS NULL OR StartDate IS NULL OR EndDate > StartDate"]),
    T("ref", "Region", [
        ("RegionID", ID, False, ""), ("RegionCode", "VARCHAR(10)", False, ""),
        ("Name", "NVARCHAR(100)", False, ""), ("CountryCode", "CHAR(2)", True, "")],
        ["RegionID"], uniques=[["RegionCode"]]),
    T("ref", "Packhouse", [
        ("PackhouseID", ID, False, ""), ("MarketerID", "INT", False, ""),
        ("RegionID", "INT", True, ""), ("PHC", "VARCHAR(20)", True, ""),
        ("Name", "NVARCHAR(150)", False, ""), ("Address", "NVARCHAR(400)", True, ""),
        ("PublishFolder", "NVARCHAR(400)", True, ""), ACTIVE],
        ["PackhouseID"], uniques=[["MarketerID", "Name"]],
        fks=[("MarketerID", "ref.Marketer", "MarketerID"), ("RegionID", "ref.Region", "RegionID")],
        doc="Receives its own published copy for its BarTender print station."),
    T("ref", "Farm", [
        ("FarmID", ID, False, ""), ("MarketerID", "INT", False, ""),
        ("PUC", "VARCHAR(20)", False, ""), ("Name", "NVARCHAR(150)", False, ""),
        ("PucName", "NVARCHAR(150)", True, ""), ("PHC", "VARCHAR(20)", True, ""),
        ("GGN", "VARCHAR(13)", True, ""), ("GLN", "VARCHAR(13)", True, ""),
        ("FloID", "VARCHAR(20)", True, ""), ("CountryCode", "CHAR(2)", True, ""),
        ("Address", "NVARCHAR(400)", True, ""), ("RegionID", "INT", True, ""), ACTIVE],
        ["FarmID"], uniques=[["MarketerID", "PUC"]],
        fks=[("MarketerID", "ref.Marketer", "MarketerID"), ("RegionID", "ref.Region", "RegionID")],
        checks=[DIGITS13.format(c="GGN"), DIGITS13.format(c="GLN")]),
    T("ref", "Commodity", [
        ("CommodityCode", "VARCHAR(4)", False, ""), ("Name", "NVARCHAR(50)", False, "")],
        ["CommodityCode"]),
    T("ref", "VarietyGroup", [
        ("VarietyGroupID", ID, False, ""), ("CommodityCode", "VARCHAR(4)", False, ""),
        ("VarietyGroupCode", "VARCHAR(10)", True, ""), ("Name", "NVARCHAR(100)", False, ""),
        ("Colour", "VARCHAR(10)", True, "")],
        ["VarietyGroupID"], uniques=[["CommodityCode", "Name"]],
        fks=[("CommodityCode", "ref.Commodity", "CommodityCode")],
        checks=["Colour IS NULL OR Colour IN ('White','Red','Black','Mixed')"]),
    T("ref", "Variety", [
        ("VarietyID", ID, False, ""), ("CommodityCode", "VARCHAR(4)", False, ""),
        ("VarietyCode", "VARCHAR(10)", False, ""), ("Name", "NVARCHAR(150)", False, ""),
        ("LongName", "NVARCHAR(250)", True, ""), ("VarietyGroupID", "INT", True, ""),
        ("IsMix", "BIT", False, "DEFAULT (0)"), ACTIVE],
        ["VarietyID"], uniques=[["CommodityCode", "VarietyCode"]],
        fks=[("CommodityCode", "ref.Commodity", "CommodityCode"),
             ("VarietyGroupID", "ref.VarietyGroup", "VarietyGroupID")],
        doc="Name = short name (IFG 68-175); LongName = with trademark (IFG 68-175 (SWEET CELEBRATION™))."),
    T("ref", "MixVariety", [
        ("VarietyID", "INT", False, ""), ("VarietyA_ID", "INT", False, ""),
        ("VarietyB_ID", "INT", False, ""), ("DisplayName", "NVARCHAR(300)", True, "")],
        ["VarietyID"],
        fks=[("VarietyID", "ref.Variety", "VarietyID"), ("VarietyA_ID", "ref.Variety", "VarietyID"),
             ("VarietyB_ID", "ref.Variety", "VarietyID")],
        checks=["VarietyA_ID <> VarietyB_ID"]),
    T("ref", "Orchard", [
        ("OrchardID", ID, False, ""), ("FarmID", "INT", False, ""),
        ("SeasonID", "INT", False, ""), ("OrchardCode", "NVARCHAR(30)", False, ""),
        ("VarietyID", "INT", False, ""), ("Licence1", "NVARCHAR(50)", True, ""),
        ("Licence2", "NVARCHAR(50)", True, ""), ("IsMixOrchard", "BIT", False, "DEFAULT (0)"), ACTIVE],
        ["OrchardID"], uniques=[["FarmID", "SeasonID", "OrchardCode", "VarietyID"]],
        fks=[("FarmID", "ref.Farm", "FarmID"), ("SeasonID", "ref.Season", "SeasonID"),
             ("VarietyID", "ref.Variety", "VarietyID")],
        doc="Licence1/2 = plant-breeder licence numbers."),
    T("ref", "Pack", [
        ("PackID", ID, False, ""), ("CommodityCode", "VARCHAR(4)", False, ""),
        ("PackCode", "VARCHAR(10)", False, ""), ("InnerPack", "NVARCHAR(50)", True, ""),
        ("NetWeight", "NVARCHAR(20)", True, "")],
        ["PackID"], uniques=[["CommodityCode", "PackCode"]],
        fks=[("CommodityCode", "ref.Commodity", "CommodityCode")]),
    T("ref", "TargetMarket", [
        ("TargetMarketCode", "VARCHAR(10)", False, ""), ("Name", "NVARCHAR(100)", True, "")],
        ["TargetMarketCode"]),
    T("ref", "Gtin", [
        ("GtinID", ID, False, ""), ("MarketerID", "INT", False, ""),
        ("GTIN", "CHAR(14)", False, ""), ("CommodityCode", "VARCHAR(4)", False, ""),
        ("VarietyCode", "VARCHAR(10)", True, ""), ("VarietyGroupCode", "VARCHAR(10)", True, ""),
        ("PackCode", "VARCHAR(10)", True, ""), ("Grade", "VARCHAR(10)", True, ""),
        ("Mark", "VARCHAR(10)", True, ""), ("InventoryCode", "VARCHAR(10)", True, ""),
        ("SizeCount", "VARCHAR(10)", True, ""), ("CountryCode", "CHAR(2)", True, ""), ACTIVE],
        ["GtinID"], uniques=[["MarketerID", "GTIN"]],
        fks=[("MarketerID", "ref.Marketer", "MarketerID"), ("CommodityCode", "ref.Commodity", "CommodityCode")],
        checks=["GTIN NOT LIKE '%[^0-9]%' AND LEN(GTIN) = 14"],
        doc="From the Paltrack R2 GTIN export / masterfile builder. Check digit verified by ops.vw_DataProblems."),
    T("ref", "GtinTargetMarket", [
        ("GtinID", "INT", False, ""), ("TargetMarketCode", "VARCHAR(10)", False, ""), ACTIVE],
        ["GtinID", "TargetMarketCode"],
        fks=[("GtinID", "ref.Gtin", "GtinID"), ("TargetMarketCode", "ref.TargetMarket", "TargetMarketCode")]),

    # -------------------------------------------------------------- label
    T("label", "Retailer", [
        ("RetailerID", ID, False, ""), ("MarketerID", "INT", False, ""),
        ("Name", "NVARCHAR(100)", False, ""), ("Programme", "NVARCHAR(100)", True, ""),
        ("ImporterName", "NVARCHAR(200)", True, ""), ("ImporterAddress", "NVARCHAR(400)", True, ""),
        ("LotCodeRule", "NVARCHAR(200)", True, ""), ACTIVE],
        ["RetailerID"], uniques=[["MarketerID", "Name", "Programme"]],
        fks=[("MarketerID", "ref.Marketer", "MarketerID")],
        doc="LotCodeRule: what the L- code means for this retailer (batch no., packing month, code)."),
    T("label", "CodeType", [
        ("CodeType", "VARCHAR(30)", False, ""), ("Description", "NVARCHAR(200)", True, "")],
        ["CodeType"]),
    T("label", "RetailerCode", [
        ("RetailerCodeID", ID, False, ""), ("RetailerID", "INT", False, ""),
        ("CodeType", "VARCHAR(30)", False, ""), ("FarmID", "INT", True, ""),
        ("VarietyID", "INT", True, ""), ("VarietyGroupID", "INT", True, ""),
        ("PackID", "INT", True, ""), ("CountryCode", "CHAR(2)", True, ""),
        ("Value", "NVARCHAR(100)", False, ""), ("Notes", "NVARCHAR(200)", True, "")],
        ["RetailerCodeID"],
        fks=[("RetailerID", "label.Retailer", "RetailerID"), ("CodeType", "label.CodeType", "CodeType"),
             ("FarmID", "ref.Farm", "FarmID"), ("VarietyID", "ref.Variety", "VarietyID"),
             ("VarietyGroupID", "ref.VarietyGroup", "VarietyGroupID"), ("PackID", "ref.Pack", "PackID")],
        doc="Edeka/Netto GTINs, Lidl IAN, SanLucar EAN/PL-bag, MO product codes ... scoped by whichever columns are filled."),
    T("label", "RetailerAssortment", [
        ("RetailerAssortmentID", ID, False, ""), ("RetailerID", "INT", False, ""),
        ("OrchardID", "INT", True, ""), ("FarmID", "INT", True, ""),
        ("VarietyID", "INT", True, ""), ("IsIncluded", "BIT", False, "DEFAULT (1)")],
        ["RetailerAssortmentID"],
        fks=[("RetailerID", "label.Retailer", "RetailerID"), ("OrchardID", "ref.Orchard", "OrchardID"),
             ("FarmID", "ref.Farm", "FarmID"), ("VarietyID", "ref.Variety", "VarietyID")],
        checks=["OrchardID IS NOT NULL OR FarmID IS NOT NULL OR VarietyID IS NOT NULL"]),
    T("label", "Language", [
        ("LanguageCode", "VARCHAR(5)", False, ""), ("Name", "NVARCHAR(50)", False, "")],
        ["LanguageCode"]),
    T("label", "Translation", [
        ("TranslationID", ID, False, ""), ("EntityType", "VARCHAR(30)", False, ""),
        ("EntityKey", "NVARCHAR(100)", False, ""), ("LanguageCode", "VARCHAR(5)", False, ""),
        ("RetailerID", "INT", True, ""), ("Text", "NVARCHAR(400)", False, "")],
        ["TranslationID"], uniques=[["EntityType", "EntityKey", "LanguageCode", "RetailerID"]],
        fks=[("LanguageCode", "label.Language", "LanguageCode"), ("RetailerID", "label.Retailer", "RetailerID")],
        checks=["EntityType IN ('VarietyGroup','Variety','Origin','Country','Grade','Count','BrandMark','Other')"]),
    T("label", "OutputTable", [
        ("OutputTableID", ID, False, ""), ("MarketerID", "INT", False, ""),
        ("RegionID", "INT", True, ""), ("AccessTableName", "NVARCHAR(128)", False, ""),
        ("ViewName", "NVARCHAR(256)", True, ""), ACTIVE],
        ["OutputTableID"], uniques=[["MarketerID", "RegionID", "AccessTableName"]],
        fks=[("MarketerID", "ref.Marketer", "MarketerID"), ("RegionID", "ref.Region", "RegionID")],
        doc="Each table a publish must produce, with the exact name BarTender reads."),
    T("label", "OutputColumn", [
        ("OutputColumnID", ID, False, ""), ("OutputTableID", "INT", False, ""),
        ("Ordinal", "INT", False, ""), ("AccessColumnName", "NVARCHAR(128)", False, ""),
        ("SourceColumn", "NVARCHAR(128)", True, "")],
        ["OutputColumnID"], uniques=[["OutputTableID", "Ordinal"]],
        fks=[("OutputTableID", "label.OutputTable", "OutputTableID")]),

    # ---------------------------------------------------------------- ops
    T("ops", "ImportBatch", [
        ("ImportBatchID", ID, False, ""), ("Source", "NVARCHAR(400)", False, ""),
        ("MarketerID", "INT", True, ""), ("Status", "VARCHAR(10)", False, "DEFAULT ('Pending')"),
        ("ReviewedBy", "NVARCHAR(128)", True, ""), ("ReviewedAt", "DATETIME2(0)", True, ""),
        ("Notes", "NVARCHAR(1000)", True, "")],
        ["ImportBatchID"], fks=[("MarketerID", "ref.Marketer", "MarketerID")],
        checks=["Status IN ('Pending','Approved','Rejected','Applied')"]),
    T("ops", "ImportChange", [
        ("ImportChangeID", ID, False, ""), ("ImportBatchID", "INT", False, ""),
        ("TableName", "NVARCHAR(128)", False, ""), ("RecordKey", "NVARCHAR(200)", False, ""),
        ("FieldName", "NVARCHAR(128)", True, ""), ("OldValue", "NVARCHAR(MAX)", True, ""),
        ("NewValue", "NVARCHAR(MAX)", True, ""), ("ChangeType", "VARCHAR(10)", False, ""),
        ("Status", "VARCHAR(10)", False, "DEFAULT ('Pending')")],
        ["ImportChangeID"], fks=[("ImportBatchID", "ops.ImportBatch", "ImportBatchID")],
        checks=["ChangeType IN ('Insert','Update','Delete')",
                "Status IN ('Pending','Approved','Rejected','Applied')"]),
    T("ops", "PublishLog", [
        ("PublishLogID", ID, False, ""), ("PackhouseID", "INT", False, ""),
        ("SeasonID", "INT", False, ""), ("StartedAt", "DATETIME2(0)", False, "DEFAULT (SYSUTCDATETIME())"),
        ("FinishedAt", "DATETIME2(0)", True, ""), ("Result", "VARCHAR(15)", False, ""),
        ("FileName", "NVARCHAR(400)", True, ""), ("FileSha256", "CHAR(64)", True, ""),
        ("TotalRows", "INT", True, ""), ("Message", "NVARCHAR(MAX)", True, "")],
        ["PublishLogID"],
        fks=[("PackhouseID", "ref.Packhouse", "PackhouseID"), ("SeasonID", "ref.Season", "SeasonID")],
        checks=["Result IN ('Published','PlacedBeside','Blocked','Failed')"], temporal=False),
    T("ops", "ChangeRequest", [
        ("ChangeRequestID", ID, False, ""), ("PackhouseID", "INT", False, ""),
        ("PublishLogID", "INT", True, ""), ("AccessTableName", "NVARCHAR(128)", False, ""),
        ("RecordKey", "NVARCHAR(200)", True, ""), ("FieldName", "NVARCHAR(128)", True, ""),
        ("OldValue", "NVARCHAR(MAX)", True, ""), ("NewValue", "NVARCHAR(MAX)", True, ""),
        ("ChangeType", "VARCHAR(10)", False, ""), ("Status", "VARCHAR(10)", False, "DEFAULT ('Pending')"),
        ("ReceivedAt", "DATETIME2(0)", False, "DEFAULT (SYSUTCDATETIME())"),
        ("ReviewedBy", "NVARCHAR(128)", True, ""), ("ReviewedAt", "DATETIME2(0)", True, ""),
        ("ReviewComment", "NVARCHAR(1000)", True, "")],
        ["ChangeRequestID"],
        fks=[("PackhouseID", "ref.Packhouse", "PackhouseID"), ("PublishLogID", "ops.PublishLog", "PublishLogID")],
        checks=["ChangeType IN ('Insert','Update','Delete','NewColumn')",
                "Status IN ('Pending','Approved','Rejected','Applied')"]),
    T("ops", "ValidationResult", [
        ("ValidationResultID", ID, False, ""), ("RunAt", "DATETIME2(0)", False, "DEFAULT (SYSUTCDATETIME())"),
        ("PackhouseID", "INT", True, ""), ("RuleCode", "VARCHAR(50)", False, ""),
        ("Severity", "VARCHAR(10)", False, ""), ("TableName", "NVARCHAR(128)", True, ""),
        ("RecordKey", "NVARCHAR(200)", True, ""), ("Message", "NVARCHAR(1000)", False, "")],
        ["ValidationResultID"], fks=[("PackhouseID", "ref.Packhouse", "PackhouseID")],
        checks=["Severity IN ('Error','Warning')"], temporal=False),

    # ---------------------------------------------------------------- sec
    T("sec", "AppUser", [
        ("AppUserID", ID, False, ""), ("WindowsLogin", "NVARCHAR(128)", False, ""),
        ("DisplayName", "NVARCHAR(100)", False, ""), ("Role", "VARCHAR(20)", False, ""),
        ACTIVE, ("LastSeenAt", "DATETIME2(0)", True, "")],
        ["AppUserID"], uniques=[["WindowsLogin"]],
        checks=["Role IN ('Admin','Technician','Viewer')"]),
]

STAMPS = [
    "    CreatedBy  NVARCHAR(160) NOT NULL CONSTRAINT DF_{s}_{n}_CreatedBy  DEFAULT (sec.fn_CurrentUser()),",
    "    CreatedAt  DATETIME2(0)  NOT NULL CONSTRAINT DF_{s}_{n}_CreatedAt  DEFAULT (SYSUTCDATETIME()),",
    "    ModifiedBy NVARCHAR(160) NOT NULL CONSTRAINT DF_{s}_{n}_ModifiedBy DEFAULT (sec.fn_CurrentUser()),",
    "    ModifiedAt DATETIME2(0)  NOT NULL CONSTRAINT DF_{s}_{n}_ModifiedAt DEFAULT (SYSUTCDATETIME()),",
    "    RowVer     ROWVERSION    NOT NULL,",
]
PERIOD = [
    "    ValidFrom  DATETIME2(7) GENERATED ALWAYS AS ROW START HIDDEN NOT NULL,",
    "    ValidTo    DATETIME2(7) GENERATED ALWAYS AS ROW END   HIDDEN NOT NULL,",
    "    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo),",
]


def table_sql(t):
    s, n = t["schema"], t["name"]
    out = []
    if t["doc"]:
        out.append(f"-- {t['doc']}")
    out.append(f"IF OBJECT_ID(N'{s}.{n}', N'U') IS NULL")
    out.append("BEGIN")
    out.append(f"CREATE TABLE {s}.{n} (")
    for name, typ, null, extra in t["cols"]:
        default = ""
        if extra.startswith("DEFAULT"):
            default = f" CONSTRAINT DF_{s}_{n}_{name} {extra}"
            extra = ""
        out.append(f"    {name:<16} {typ:<14} {'NULL' if null else 'NOT NULL'}{(' ' + extra) if extra else ''}{default},")
    out += [x.format(s=s, n=n) for x in STAMPS]
    if t["temporal"]:
        out += PERIOD
    out.append(f"    CONSTRAINT PK_{s}_{n} PRIMARY KEY ({', '.join(t['pk'])}),")
    for u in t["uniques"]:
        out.append(f"    CONSTRAINT UQ_{s}_{n}_{'_'.join(u)} UNIQUE ({', '.join(u)}),")
    for col, ref, refcol in t["fks"]:
        out.append(f"    CONSTRAINT FK_{s}_{n}_{col} FOREIGN KEY ({col}) REFERENCES {ref} ({refcol}),")
    for i, c in enumerate(t["checks"], 1):
        out.append(f"    CONSTRAINT CK_{s}_{n}_{i} CHECK ({c}),")
    out[-1] = out[-1].rstrip(",")
    if t["temporal"]:
        out.append(f") WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = {s}.{n}History));")
    else:
        out.append(");")
    out.append("END;")
    out.append("GO")
    out.append("")
    return "\n".join(out)


def trigger_sql(t):
    s, n = t["schema"], t["name"]
    on = " AND ".join(f"t.{k} = i.{k}" for k in t["pk"])
    ond = " AND ".join(f"d.{k} = i.{k}" for k in t["pk"])
    return f"""CREATE OR ALTER TRIGGER {s}.trg_{n}_Stamp ON {s}.{n}
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL(@@PROCID) > 1 RETURN;      -- don't re-fire on our own update
    DECLARE @who NVARCHAR(160) = sec.fn_CurrentUser(), @now DATETIME2(0) = SYSUTCDATETIME();
    UPDATE t
       SET ModifiedBy = @who,
           ModifiedAt = @now,
           CreatedBy  = COALESCE(d.CreatedBy, @who),   -- creator can't be changed or faked
           CreatedAt  = COALESCE(d.CreatedAt, @now)
      FROM {s}.{n} AS t
      JOIN inserted AS i ON {on}
      LEFT JOIN deleted AS d ON {ond};
END;
GO
"""


def header(title, number):
    return (f"/* {number} - {title}\n"
            f"   GENERATED by database/tools/generate_migrations.py - edit the generator, not this file.\n"
            f"   Run in SQL Server Management Studio against {DB}. Safe to re-run (skips existing tables). */\n"
            f"USE [{DB}];\nGO\nSET ANSI_NULLS ON;\nSET QUOTED_IDENTIFIER ON;\nGO\n\n")


def main():
    groups = [("003_ref_tables.sql", "Reference tables (ref)", "ref"),
              ("004_label_tables.sql", "Retailer label tables (label)", "label"),
              ("005_ops_sec_tables.sql", "Operations and security tables (ops, sec)", ("ops", "sec"))]
    for fname, title, schemas in groups:
        schemas = (schemas,) if isinstance(schemas, str) else schemas
        body = "".join(table_sql(t) for t in TABLES if t["schema"] in schemas)
        with open(os.path.join(OUT, fname), "w", encoding="utf-8", newline="\r\n") as f:
            f.write(header(title, fname[:3]) + body)
    body = "".join(trigger_sql(t) for t in TABLES)
    with open(os.path.join(OUT, "006_stamp_triggers.sql"), "w", encoding="utf-8", newline="\r\n") as f:
        f.write(header("Stamp triggers: who changed what, when", "006") + body)
    print(f"Generated {len(TABLES)} tables.")


if __name__ == "__main__":
    main()
