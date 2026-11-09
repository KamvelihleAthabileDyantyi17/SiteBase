Attribute VB_Name = "modSiteBaseConfig"
'===============================================================================
' SiteBase - connection settings for this Access front end
'
' This is the EXAMPLE file kept in Git. After importing it into Access, change
' SB_SERVER to the real server (e.g. "192.168.x.x,1433") inside Access only.
' The real value lives in the .accdb, which Git ignores.
'===============================================================================
Option Compare Database
Option Explicit

Public Const SB_SERVER As String = "SERVER-ADDRESS,1433"
Public Const SB_DATABASE As String = "SiteBase_Dev"
Public Const SB_DRIVER As String = "ODBC Driver 17 for SQL Server"

' South Africa is UTC+2 all year (no daylight saving). Stamps are stored in UTC.
Public Const SB_UTC_OFFSET_HOURS As Integer = 2
