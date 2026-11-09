/* 009 - Fixed lookup values (no client data)
   Run against SiteBase_Dev. Safe to re-run: only adds what is missing. */
USE [SiteBase_Dev];
GO
INSERT INTO ref.Commodity (CommodityCode, Name)
SELECT v.c, v.n FROM (VALUES ('GR', N'Grapes')) v(c, n)
WHERE NOT EXISTS (SELECT 1 FROM ref.Commodity x WHERE x.CommodityCode = v.c);

INSERT INTO label.Language (LanguageCode, Name)
SELECT v.c, v.n FROM (VALUES
    ('en', N'English'), ('de', N'German'), ('cs', N'Czech'), ('hr', N'Croatian'),
    ('pl', N'Polish'), ('ro', N'Romanian'), ('bg', N'Bulgarian'), ('sk', N'Slovak'),
    ('lb', N'Luxembourgish'), ('fr', N'French'), ('ar', N'Arabic'), ('ru', N'Russian')) v(c, n)
WHERE NOT EXISTS (SELECT 1 FROM label.Language x WHERE x.LanguageCode = v.c);

INSERT INTO label.CodeType (CodeType, Description)
SELECT v.c, v.d FROM (VALUES
    ('RETAILER_GTIN', N'Retailer''s own consumer-unit GTIN (e.g. Edeka, Netto)'),
    ('CARTON_GTIN',   N'Carton GTIN'),
    ('EAN13',         N'EAN-13 barcode value'),
    ('CODE128',       N'Code 128 barcode value'),
    ('IAN',           N'Lidl IAN code'),
    ('PL_BAG',        N'Private-label bag code (e.g. SanLucar)'),
    ('PRODUCT_CODE',  N'Retailer product code (e.g. MO product code)'),
    ('FARM_CODE',     N'Retailer-specific farm or packhouse code')) v(c, d)
WHERE NOT EXISTS (SELECT 1 FROM label.CodeType x WHERE x.CodeType = v.c);
GO
PRINT 'Lookup data ready.';
