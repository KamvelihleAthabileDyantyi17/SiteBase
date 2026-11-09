/* 001 - Create the SiteBase development database
   Run in SQL Server Management Studio, connected to the server (master).
   Creates SiteBase_Dev only. It never touches any other database. Safe to re-run. */
USE [master];
GO
IF DB_ID(N'SiteBase_Dev') IS NULL
    CREATE DATABASE [SiteBase_Dev];
GO
-- Readers don't block writers: technicians browsing never hold up someone saving.
ALTER DATABASE [SiteBase_Dev] SET READ_COMMITTED_SNAPSHOT ON WITH ROLLBACK IMMEDIATE;
-- Development database: simple recovery (full nightly backups, no log backups).
ALTER DATABASE [SiteBase_Dev] SET RECOVERY SIMPLE;
GO
PRINT 'SiteBase_Dev is ready.';
