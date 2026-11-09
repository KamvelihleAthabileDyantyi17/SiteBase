/* 010 - Give a technician access (TEMPLATE: copy, fill in, run once per person)
   Replace DOMAIN\username and the display name. Role: Admin, Technician or Viewer. */
USE [master];
GO
IF SUSER_ID(N'DOMAIN\username') IS NULL
    CREATE LOGIN [DOMAIN\username] FROM WINDOWS;
GO
USE [SiteBase_Dev];
GO
IF DATABASE_PRINCIPAL_ID(N'DOMAIN\username') IS NULL
    CREATE USER [DOMAIN\username] FOR LOGIN [DOMAIN\username];
ALTER ROLE SiteBase_Technician ADD MEMBER [DOMAIN\username];   -- or SiteBase_Admin / SiteBase_Viewer

IF NOT EXISTS (SELECT 1 FROM sec.AppUser WHERE WindowsLogin = N'DOMAIN\username')
    INSERT INTO sec.AppUser (WindowsLogin, DisplayName, Role) VALUES (N'DOMAIN\username', N'Display Name', 'Technician');
GO
