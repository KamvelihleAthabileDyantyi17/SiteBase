/* 007 - Data checks and handy views
   Run against SiteBase_Dev. Safe to re-run. */
USE [SiteBase_Dev];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* Every data problem that would stop (Error) or should be looked at before
   (Warning) a publish. The publish step refuses to run while Errors exist
   for the packhouse's data.
       SELECT * FROM ops.vw_DataProblems ORDER BY Severity, RuleCode;        */
CREATE OR ALTER VIEW ops.vw_DataProblems
AS
SELECT 'GTIN_CHECK_DIGIT' AS RuleCode, 'Error' AS Severity, 'ref.Gtin' AS TableName,
       g.GTIN AS RecordKey, N'GTIN check digit is wrong' AS Message, g.MarketerID
  FROM ref.Gtin g WHERE g.IsActive = 1 AND ref.fn_Gs1CheckDigitOK(g.GTIN) = 0
UNION ALL
SELECT 'FARM_NO_GGN', 'Error', 'ref.Farm', f.PUC, N'Farm ' + f.Name + N' has no GGN', f.MarketerID
  FROM ref.Farm f WHERE f.IsActive = 1 AND f.GGN IS NULL
UNION ALL
SELECT 'FARM_GGN_CHECK_DIGIT', 'Warning', 'ref.Farm', f.PUC, N'GGN ' + f.GGN + N' check digit is wrong', f.MarketerID
  FROM ref.Farm f WHERE f.GGN IS NOT NULL AND ref.fn_Gs1CheckDigitOK(f.GGN) = 0
UNION ALL
SELECT 'FARM_GLN_CHECK_DIGIT', 'Error', 'ref.Farm', f.PUC, N'GLN ' + f.GLN + N' check digit is wrong', f.MarketerID
  FROM ref.Farm f WHERE f.GLN IS NOT NULL AND ref.fn_Gs1CheckDigitOK(f.GLN) = 0
UNION ALL
SELECT 'ORCHARD_INACTIVE_LINK', 'Error', 'ref.Orchard',
       f.PUC + N' / ' + o.OrchardCode, N'Active orchard uses an inactive farm or variety', f.MarketerID
  FROM ref.Orchard o JOIN ref.Farm f ON f.FarmID = o.FarmID JOIN ref.Variety v ON v.VarietyID = o.VarietyID
 WHERE o.IsActive = 1 AND (f.IsActive = 0 OR v.IsActive = 0)
UNION ALL
SELECT 'VARIETY_NO_GROUP', 'Warning', 'ref.Variety', v.VarietyCode,
       N'Variety ' + v.Name + N' has no variety group', NULL
  FROM ref.Variety v WHERE v.IsActive = 1 AND v.VarietyGroupID IS NULL
UNION ALL
SELECT 'GTIN_UNKNOWN_VARIETY', 'Warning', 'ref.Gtin', g.GTIN,
       N'GTIN uses variety code ' + g.VarietyCode + N' which is not in ref.Variety', g.MarketerID
  FROM ref.Gtin g
 WHERE g.IsActive = 1 AND g.VarietyCode IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM ref.Variety v WHERE v.CommodityCode = g.CommodityCode AND v.VarietyCode = g.VarietyCode);
GO

/* Orchards with everything a label needs, one row per orchard. */
CREATE OR ALTER VIEW ref.vw_OrchardDetail
AS
SELECT m.MarketerCode, s.SeasonCode, f.PUC, f.Name AS FarmName, f.PHC, f.GGN, f.GLN, f.CountryCode,
       o.OrchardCode, v.VarietyCode, v.Name AS VarietyName, v.LongName AS VarietyLongName,
       vg.Name AS VarietyGroup, vg.Colour, o.Licence1, o.Licence2, o.IsMixOrchard,
       o.OrchardID, o.FarmID, o.VarietyID, o.SeasonID
  FROM ref.Orchard o
  JOIN ref.Farm f    ON f.FarmID = o.FarmID
  JOIN ref.Marketer m ON m.MarketerID = f.MarketerID
  JOIN ref.Season s  ON s.SeasonID = o.SeasonID
  JOIN ref.Variety v ON v.VarietyID = o.VarietyID
  LEFT JOIN ref.VarietyGroup vg ON vg.VarietyGroupID = v.VarietyGroupID
 WHERE o.IsActive = 1;
GO
PRINT 'Checks and views ready.';
