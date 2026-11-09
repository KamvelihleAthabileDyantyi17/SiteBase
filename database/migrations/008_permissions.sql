/* 008 - What each role may do
   Run against SiteBase_Dev after 003-007. Safe to re-run. */
USE [SiteBase_Dev];
GO
-- Viewer: look only
GRANT SELECT ON SCHEMA::ref   TO SiteBase_Viewer;
GRANT SELECT ON SCHEMA::label TO SiteBase_Viewer;
GRANT SELECT ON SCHEMA::ops   TO SiteBase_Viewer;

-- Technician: edit master data, work the change-request inbox, publish
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::ref   TO SiteBase_Technician;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::label TO SiteBase_Technician;
GRANT SELECT, INSERT, UPDATE         ON SCHEMA::ops   TO SiteBase_Technician;
GRANT SELECT                         ON SCHEMA::sec   TO SiteBase_Technician;
GRANT EXECUTE ON SCHEMA::ref TO SiteBase_Technician;
GRANT EXECUTE ON SCHEMA::sec TO SiteBase_Technician;

-- Admin: everything inside SiteBase, including the user list and design changes
GRANT CONTROL ON SCHEMA::ref   TO SiteBase_Admin;
GRANT CONTROL ON SCHEMA::label TO SiteBase_Admin;
GRANT CONTROL ON SCHEMA::ops   TO SiteBase_Admin;
GRANT CONTROL ON SCHEMA::sec   TO SiteBase_Admin;

-- Everyone in a SiteBase role can read the current-user function
GRANT EXECUTE ON sec.fn_CurrentUser TO SiteBase_Viewer;
GO
PRINT 'Permissions granted.';
