/* 002 - Schemas, roles and helper functions
   Run against SiteBase_Dev. Safe to re-run. */
USE [SiteBase_Dev];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- Schemas -----------------------------------------------------------------
IF SCHEMA_ID(N'ref')   IS NULL EXEC (N'CREATE SCHEMA ref');    -- reference data
IF SCHEMA_ID(N'label') IS NULL EXEC (N'CREATE SCHEMA label');  -- retailer label data
IF SCHEMA_ID(N'ops')   IS NULL EXEC (N'CREATE SCHEMA ops');    -- imports, publishing, change requests
IF SCHEMA_ID(N'sec')   IS NULL EXEC (N'CREATE SCHEMA sec');    -- users and roles
GO

-- Roles (permissions are granted in 008 once the tables exist) -------------
IF DATABASE_PRINCIPAL_ID(N'SiteBase_Admin')      IS NULL CREATE ROLE SiteBase_Admin;
IF DATABASE_PRINCIPAL_ID(N'SiteBase_Technician') IS NULL CREATE ROLE SiteBase_Technician;
IF DATABASE_PRINCIPAL_ID(N'SiteBase_Viewer')     IS NULL CREATE ROLE SiteBase_Viewer;
GO

-- Who is making this change?
-- The Windows login of the connection. The sync tool can add who it is acting
-- for, e.g. "DOMAIN\thabo for Packhouse 12", by setting the session value
-- SiteBase.OnBehalfOf before applying an approved packhouse change.
CREATE OR ALTER FUNCTION sec.fn_CurrentUser()
RETURNS NVARCHAR(160)
WITH INLINE = OFF   -- avoids scalar-inlining bugs in SQL Server 2019 RTM
AS
BEGIN
    DECLARE @for NVARCHAR(60) = CAST(SESSION_CONTEXT(N'SiteBase.OnBehalfOf') AS NVARCHAR(60));
    RETURN LEFT(ORIGINAL_LOGIN() + CASE WHEN @for IS NULL THEN N'' ELSE N' for ' + @for END, 160);
END;
GO

-- GS1 check digit (GTIN-14, GTIN-13/EAN-13, GLN and GGN are all GS1 numbers).
CREATE OR ALTER FUNCTION ref.fn_Gs1CheckDigitOK(@code VARCHAR(20))
RETURNS BIT
WITH INLINE = OFF
AS
BEGIN
    DECLARE @n INT = LEN(@code), @i INT = 1, @sum INT = 0;
    IF @code IS NULL OR @n NOT IN (8, 12, 13, 14) OR @code LIKE '%[^0-9]%' RETURN 0;
    WHILE @i < @n
    BEGIN
        SET @sum += CAST(SUBSTRING(@code, @i, 1) AS INT) * CASE WHEN (@n - @i) % 2 = 1 THEN 3 ELSE 1 END;
        SET @i += 1;
    END;
    RETURN CASE WHEN (10 - @sum % 10) % 10 = CAST(RIGHT(@code, 1) AS INT) THEN 1 ELSE 0 END;
END;
GO
PRINT 'Schemas, roles and functions ready.';
