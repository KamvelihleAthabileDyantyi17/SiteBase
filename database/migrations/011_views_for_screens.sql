/* 011 - Views used by the technician screens
   Run against SiteBase_Dev. Safe to re-run. */
USE [SiteBase_Dev];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
/* Latest change to every record, across the main tables: "who changed what recently?"
   (Admin screen > Recent changes). Full detail per record is in each table's history. */
CREATE OR ALTER VIEW ops.vw_RecentChanges
AS
SELECT N'Farm'          AS Screen, CAST(PUC AS NVARCHAR(200)) + N' - ' + Name AS Record, ModifiedBy, ModifiedAt FROM ref.Farm
UNION ALL
SELECT N'Orchard', CAST(f.PUC AS NVARCHAR(200)) + N' / orchard ' + o.OrchardCode, o.ModifiedBy, o.ModifiedAt
  FROM ref.Orchard o JOIN ref.Farm f ON f.FarmID = o.FarmID
UNION ALL
SELECT N'Variety',       CAST(VarietyCode AS NVARCHAR(200)) + N' - ' + Name, ModifiedBy, ModifiedAt FROM ref.Variety
UNION ALL
SELECT N'Variety group', CAST(Name AS NVARCHAR(200)), ModifiedBy, ModifiedAt FROM ref.VarietyGroup
UNION ALL
SELECT N'Pack',          CAST(PackCode AS NVARCHAR(200)), ModifiedBy, ModifiedAt FROM ref.Pack
UNION ALL
SELECT N'GTIN',          CAST(GTIN AS NVARCHAR(200)), ModifiedBy, ModifiedAt FROM ref.Gtin
UNION ALL
SELECT N'Marketer',      CAST(MarketerCode AS NVARCHAR(200)) + N' - ' + Name, ModifiedBy, ModifiedAt FROM ref.Marketer
UNION ALL
SELECT N'Season',        CAST(SeasonCode AS NVARCHAR(200)), ModifiedBy, ModifiedAt FROM ref.Season
UNION ALL
SELECT N'Packhouse',     CAST(Name AS NVARCHAR(200)), ModifiedBy, ModifiedAt FROM ref.Packhouse
UNION ALL
SELECT N'Technician',    CAST(WindowsLogin AS NVARCHAR(200)) + N' - ' + DisplayName, ModifiedBy, ModifiedAt FROM sec.AppUser;
GO
PRINT 'Screen views ready.';
