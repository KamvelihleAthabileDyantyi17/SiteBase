/* Make SiteBase_Dev yours alone (run ONCE, after 001_create_database.sql)

   What it does:
   - creates your own SQL login (pick the name and a strong password below)
   - makes that login the OWNER of SiteBase_Dev
   - switches SiteBase_Dev to RESTRICTED_USER: only its owner and server
     administrators (sysadmin, e.g. 'sa') can open it. Everyone else is
     refused, even if they know the server address.

   It does not touch CA_DBase_SQL, DummyDB, TechDB or any other database.
   Don't save your real password into this file or into Git: type it,
   run, then close the tab without saving. */
USE [master];
GO
DECLARE @login sysname = N'kamelihle_sitebase';            -- your login name
IF SUSER_ID(@login) IS NULL
    EXEC (N'CREATE LOGIN [' + @login + N'] WITH PASSWORD = N''TYPE-A-STRONG-PASSWORD-HERE'', CHECK_POLICY = ON, DEFAULT_DATABASE = [SiteBase_Dev];');
EXEC (N'ALTER AUTHORIZATION ON DATABASE::[SiteBase_Dev] TO [' + @login + N'];');
GO
ALTER DATABASE [SiteBase_Dev] SET RESTRICTED_USER WITH ROLLBACK IMMEDIATE;
GO

/* Check: who can get into SiteBase_Dev? */
SELECT d.name AS DatabaseName, SUSER_SNAME(d.owner_sid) AS Owner, d.user_access_desc AS Access
  FROM sys.databases d WHERE d.name = N'SiteBase_Dev';
SELECT name AS ServerAdmins FROM sys.server_principals p
 WHERE IS_SRVROLEMEMBER('sysadmin', p.name) = 1 AND p.type IN ('S','U','G') AND p.is_disabled = 0;
GO

/* Later, when other technicians should test (Stage 2), open it up again:
   ALTER DATABASE [SiteBase_Dev] SET MULTI_USER;                        */
