Attribute VB_Name = "modSiteBase"
'===============================================================================
' SiteBase - everyday behaviour of the technician screens
'
'   Login            SB_Login             (frmLogin button)
'   Navigation       SB_Open, SB_Exit
'   Screen buttons   SB_Refresh, SB_History, SB_Search, SB_FilterBy
'   Admin            SB_RecentChanges, SB_HomeLoad
'   Safety           SB_FormError (write conflicts, friendly server errors)
'
' Forms call these through their event properties, e.g. OnClick =SB_Refresh("frmFarms"),
' so all logic lives here and forms stay simple.
'===============================================================================
Option Compare Database
Option Explicit

Public gUser As String          ' who SQL Server says is logged in
Public gIsAdmin As Boolean      ' SiteBase_Admin role or database owner

'------------------------------------------------------------------ connection
' Connection string WITHOUT credentials. After SB_Login has connected once with
' the user's name and password, Access re-uses that cached connection for all
' linked tables and queries, so the password is never stored anywhere.
Public Function SB_BaseConnect() As String
    SB_BaseConnect = "ODBC;DRIVER={" & SB_DRIVER & "};SERVER=" & SB_SERVER & _
                     ";DATABASE=" & SB_DATABASE & ";APP=SiteBase;"
End Function

'----------------------------------------------------------------------- login
Public Function SB_Login() As Boolean
    Dim f As Form, userName As String, pwd As String
    Dim qd As DAO.QueryDef, rs As DAO.Recordset

    Set f = Forms("frmLogin")
    userName = Trim$(Nz(f!txtUser, ""))
    pwd = Nz(f!txtPassword, "")
    If userName = "" Or pwd = "" Then
        MsgBox "Type your SiteBase login and password.", vbInformation, "SiteBase"
        Exit Function
    End If

    On Error GoTo Failed
    Set qd = CurrentDb.CreateQueryDef("")
    qd.Connect = SB_BaseConnect() & "Trusted_Connection=No;UID=" & SB_OdbcValue(userName) & _
                 ";PWD=" & SB_OdbcValue(pwd) & ";"
    qd.ReturnsRecords = True
    qd.SQL = "SELECT sec.fn_CurrentUser() AS Who, " & _
             "CAST(CASE WHEN IS_MEMBER('SiteBase_Admin') = 1 OR IS_MEMBER('db_owner') = 1 THEN 1 ELSE 0 END AS int) AS IsAdmin"
    Set rs = qd.OpenRecordset(dbOpenSnapshot)
    gUser = rs!Who
    gIsAdmin = (rs!IsAdmin = 1)
    rs.Close
    On Error GoTo 0

    f!txtPassword = Null
    pwd = ""

    If Not SB_FormExists("frmHome") Then
        If Not gIsAdmin Then
            MsgBox "The SiteBase screens haven't been built in this file yet. Ask the SiteBase admin.", vbExclamation, "SiteBase"
            Exit Function
        End If
        If MsgBox("Connected as " & gUser & "." & vbCrLf & vbCrLf & _
                  "The screens haven't been built yet. Build them now? (takes about a minute)", _
                  vbQuestion + vbYesNo, "SiteBase") <> vbYes Then Exit Function
        SB_BuildAll
    End If

    DoCmd.Close acForm, "frmLogin"
    DoCmd.OpenForm "frmHome"
    SB_Login = True
    Exit Function

Failed:
    Dim detail As String
    detail = SB_ServerReason(userName, pwd)
    pwd = ""
    MsgBox "Could not log in." & vbCrLf & vbCrLf & detail, vbExclamation, "SiteBase"
End Function

' Wrap a value in {braces} so passwords containing ; = { } are passed safely.
Public Function SB_OdbcValue(ByVal v As String) As String
    SB_OdbcValue = "{" & Replace(v, "}", "}}") & "}"
End Function

' Access only says "ODBC--connection failed". Ask SQL Server directly (via ADO)
' for the real reason, and translate the common ones.
Private Function SB_ServerReason(ByVal userName As String, ByVal pwd As String) As String
    Dim cn As Object, raw As String, i As Long
    On Error Resume Next
    Set cn = CreateObject("ADODB.Connection")
    cn.ConnectionTimeout = 10
    cn.Open "Provider=MSDASQL;DRIVER={" & SB_DRIVER & "};SERVER=" & SB_SERVER & ";DATABASE=" & SB_DATABASE & _
            ";Trusted_Connection=No;UID=" & SB_OdbcValue(userName) & ";PWD=" & SB_OdbcValue(pwd) & ";"
    If Err.Number = 0 Then
        cn.Close
        SB_ServerReason = "The server accepted the login when tested directly, so the problem is in Access's connection. " & _
                          "Send this message to the SiteBase admin." & vbCrLf & vbCrLf & SB_OdbcMessage()
        Exit Function
    End If
    raw = Err.Description
    For i = 0 To cn.Errors.Count - 1
        raw = raw & vbCrLf & cn.Errors(i).Description
    Next
    On Error GoTo 0

    If InStr(raw, "Login failed") > 0 Then
        SB_ServerReason = "Wrong login name or password (or the login doesn't exist)."
    ElseIf InStr(raw, "Cannot open database") > 0 Then
        SB_ServerReason = "Your login works, but it isn't allowed into " & SB_DATABASE & " yet. Ask the SiteBase admin."
    ElseIf InStr(raw, "locked out") > 0 Then
        SB_ServerReason = "This login is locked after too many wrong passwords. An admin must unlock it."
    ElseIf InStr(raw, "Data source name not found") > 0 Or InStr(raw, "driver") > 0 And InStr(raw, "not found") > 0 Then
        SB_ServerReason = "The SQL Server driver '" & SB_DRIVER & "' isn't installed on this PC."
    ElseIf InStr(raw, "not found or not accessible") > 0 Or InStr(raw, "network-related") > 0 Or _
           InStr(raw, "TCP Provider") > 0 Or InStr(raw, "timeout") > 0 Then
        SB_ServerReason = "Can't reach the server " & SB_SERVER & ". Check you're on the office network and the address in modSiteBaseConfig."
    Else
        SB_ServerReason = "The server said:"
    End If
    SB_ServerReason = SB_ServerReason & vbCrLf & vbCrLf & "(Details: " & Left$(raw, 500) & ")"
End Function

Public Function SB_UserName() As String
    SB_UserName = IIf(gUser = "", "(not logged in)", gUser)
End Function

'------------------------------------------------------------------ navigation
Public Function SB_Open(ByVal formName As String)
    If gUser = "" Then
        MsgBox "Please log in first.", vbInformation, "SiteBase"
        DoCmd.OpenForm "frmLogin"
        Exit Function
    End If
    DoCmd.OpenForm formName
End Function

Public Function SB_CloseScreen(ByVal formName As String)
    DoCmd.Close acForm, formName
End Function

Public Function SB_Exit()
    Application.Quit acQuitSaveNone
End Function

Public Function SB_HomeLoad()
    On Error Resume Next
    Forms("frmHome")!btnAdmin.Visible = gIsAdmin
End Function

'-------------------------------------------------------------- screen buttons
Public Function SB_Refresh(ByVal screenName As String)
    On Error Resume Next
    Forms(screenName)!subData.Form.Requery
End Function

' Filter the list by any part of a value, e.g. part of a GTIN or farm name.
Public Function SB_Search(ByVal screenName As String, ByVal fieldName As String, ByVal boxName As String)
    Dim sf As Form, v As String
    Set sf = Forms(screenName)!subData.Form
    v = Trim$(Nz(Forms(screenName)(boxName), ""))
    If v = "" Then
        sf.FilterOn = False
    Else
        sf.Filter = "[" & fieldName & "] Like '*" & Replace(v, "'", "''") & "*'"
        sf.FilterOn = True
    End If
End Function

' Filter the list to one value picked in a drop-down, e.g. one farm's orchards.
Public Function SB_FilterBy(ByVal screenName As String, ByVal fieldName As String, ByVal comboName As String)
    Dim sf As Form, v As Variant
    Set sf = Forms(screenName)!subData.Form
    v = Forms(screenName)(comboName)
    If IsNull(v) Then
        sf.FilterOn = False
    Else
        sf.Filter = "[" & fieldName & "] = " & v
        sf.FilterOn = True
    End If
End Function

'--------------------------------------------------------- "who changed this?"
' Shows every version of the selected record, newest first, from SQL Server's
' history (temporal tables): who changed it, from when until when, and the values.
Public Function SB_History(ByVal screenName As String)
    Dim sqlTable As String, pk As String, sf As Form, keyValue As Variant, sql As String

    If Not SB_ScreenTable(screenName, sqlTable, pk) Then Exit Function
    Set sf = Forms(screenName)!subData.Form
    On Error Resume Next
    keyValue = sf(pk)
    On Error GoTo 0
    If IsNull(keyValue) Or IsEmpty(keyValue) Then
        MsgBox "Click on a saved record first.", vbInformation, "SiteBase"
        Exit Function
    End If

    sql = "SELECT ModifiedBy AS [Changed by], " & _
          "CONVERT(varchar(19), DATEADD(hour, " & SB_UTC_OFFSET_HOURS & ", ValidFrom), 120) AS [From], " & _
          "CASE WHEN ValidTo >= '9999-01-01' THEN 'now (current)' " & _
          "ELSE CONVERT(varchar(19), DATEADD(hour, " & SB_UTC_OFFSET_HOURS & ", ValidTo), 120) END AS [Until], * " & _
          "FROM " & sqlTable & " FOR SYSTEM_TIME ALL WHERE " & pk & " = " & keyValue & " ORDER BY ValidFrom DESC"
    SB_RunPassThrough "qptHistory", sql
End Function

Public Function SB_RecentChanges()
    SB_RunPassThrough "qptRecentChanges", _
        "SELECT TOP 300 Screen, Record, ModifiedBy AS [Changed by], " & _
        "CONVERT(varchar(19), DATEADD(hour, " & SB_UTC_OFFSET_HOURS & ", ModifiedAt), 120) AS [When] " & _
        "FROM ops.vw_RecentChanges ORDER BY ModifiedAt DESC"
End Function

Private Sub SB_RunPassThrough(ByVal queryName As String, ByVal sql As String)
    Dim db As DAO.Database, qd As DAO.QueryDef
    Set db = CurrentDb
    On Error Resume Next
    DoCmd.Close acQuery, queryName
    db.QueryDefs.Delete queryName
    On Error GoTo Failed
    Set qd = db.CreateQueryDef(queryName)
    qd.Connect = SB_BaseConnect()
    qd.ReturnsRecords = True
    qd.SQL = sql
    DoCmd.OpenQuery queryName, acViewNormal, acReadOnly
    Exit Sub
Failed:
    MsgBox "Could not load the history." & vbCrLf & vbCrLf & SB_OdbcMessage(), vbExclamation, "SiteBase"
End Sub

' Which SQL table and key column sit behind each screen.
Public Function SB_ScreenTable(ByVal screenName As String, ByRef sqlTable As String, ByRef pk As String) As Boolean
    SB_ScreenTable = True
    Select Case screenName
        Case "frmFarms":         sqlTable = "ref.Farm":         pk = "FarmID"
        Case "frmOrchards":      sqlTable = "ref.Orchard":      pk = "OrchardID"
        Case "frmVarieties":     sqlTable = "ref.Variety":      pk = "VarietyID"
        Case "frmVarietyGroups": sqlTable = "ref.VarietyGroup": pk = "VarietyGroupID"
        Case "frmPacks":         sqlTable = "ref.Pack":         pk = "PackID"
        Case "frmGtins":         sqlTable = "ref.Gtin":         pk = "GtinID"
        Case "frmAdmin":         sqlTable = "sec.AppUser":      pk = "AppUserID"
        Case Else
            MsgBox "This screen has no history.", vbInformation, "SiteBase"
            SB_ScreenTable = False
    End Select
End Function

'------------------------------------------------------------- defaults (new rows)
Public Function SB_DefaultMarketer() As Variant
    SB_DefaultMarketer = DLookup("MarketerID", "ref_Marketer", "IsActive = True")
End Function

Public Function SB_CurrentSeason() As Variant
    SB_CurrentSeason = DLookup("SeasonID", "ref_Season", "IsCurrent = True")
End Function

'----------------------------------------------------------- safety: form errors
' Every data screen calls this from its Form_Error event.
Public Function SB_FormError(frm As Form, ByVal DataErr As Integer) As Integer
    Select Case DataErr
        Case 7787, 7878
            ' Someone else saved this record after you started editing it.
            MsgBox "Someone else saved a change to this record while you were editing it." & vbCrLf & vbCrLf & _
                   "Your change was NOT saved, so their work hasn't been overwritten." & vbCrLf & _
                   "Press Refresh, check the record, then make your change again.", _
                   vbExclamation, "SiteBase - record changed by someone else"
            On Error Resume Next
            frm.Undo
            SB_FormError = acDataErrContinue
        Case 3146, 3155, 3156, 3157
            MsgBox "The server didn't accept this change." & vbCrLf & vbCrLf & SB_OdbcMessage(), _
                   vbExclamation, "SiteBase"
            SB_FormError = acDataErrContinue
        Case Else
            SB_FormError = acDataErrDisplay
    End Select
End Function

' Turns SQL Server's error text into something a technician can act on.
Public Function SB_OdbcMessage() As String
    Dim e As DAO.Error, raw As String, friendly As String
    For Each e In DBEngine.Errors
        raw = raw & e.Description & vbCrLf
    Next
    If InStr(raw, "Login failed") > 0 Then
        friendly = "Wrong login name or password."
    ElseIf InStr(raw, "UNIQUE KEY") > 0 Or InStr(raw, "duplicate key") > 0 Then
        friendly = "That code already exists. Each code can only be used once."
    ElseIf InStr(raw, "CHECK constraint") > 0 Then
        friendly = "A value isn't allowed here (for example: GGN and GLN must be exactly 13 digits, GTIN exactly 14)."
    ElseIf InStr(raw, "FOREIGN KEY") > 0 Then
        friendly = "This refers to something that doesn't exist, or is still in use elsewhere. Pick values from the drop-down lists."
    ElseIf InStr(raw, "permission was denied") > 0 Then
        friendly = "You don't have permission to change this. Ask the SiteBase admin."
    ElseIf InStr(raw, "Cannot insert the value NULL") > 0 Then
        friendly = "A required field is empty."
    ElseIf InStr(raw, "server was not found") > 0 Or InStr(raw, "network-related") > 0 Then
        friendly = "Can't reach the SiteBase server. Check that you're on the office network."
    End If
    If friendly <> "" Then
        SB_OdbcMessage = friendly & vbCrLf & vbCrLf & "(Details: " & Left$(raw, 400) & ")"
    Else
        SB_OdbcMessage = Left$(raw, 600)
    End If
End Function

'------------------------------------------------------------------ helpers
Public Function SB_FormExists(ByVal formName As String) As Boolean
    Dim ao As AccessObject
    For Each ao In CurrentProject.AllForms
        If ao.Name = formName Then SB_FormExists = True: Exit Function
    Next
End Function
