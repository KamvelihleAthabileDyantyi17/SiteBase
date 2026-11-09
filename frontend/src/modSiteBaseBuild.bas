Attribute VB_Name = "modSiteBaseBuild"
'===============================================================================
' SiteBase - builds the front end: linked tables and all screens.
'
' Run once, from the Immediate window (Ctrl+G):   SB_BuildLoginForm
' then open frmLogin and log in as an admin: it offers to run SB_BuildAll.
' Safe to re-run: existing links and forms are replaced.
'
' Field spec format for data screens (one string per column):
'   "Caption|Field|Kind|RowSource|DefaultValue|WidthCm"
'   Kind: T = text, L = locked text, B = yes/no, C = drop-down (ID hidden),
'         V = drop-down from a value list (RowSource "A;B;C")
'===============================================================================
Option Compare Database
Option Explicit

Private Const TWIPS_PER_CM As Long = 567

'============================================================ entry points
Public Sub SB_BuildLoginForm()
    Dim frm As Form, tmp As String, ctl As Control

    SB_DeleteForm "frmLogin"
    Set frm = CreateForm()
    tmp = frm.Name
    SB_PlainForm frm, "SiteBase - log in", 11, 7

    Set ctl = SB_Label(tmp, "SiteBase", 0.6, 0.5, 9, 1)
    ctl.FontSize = 20: ctl.FontBold = True
    SB_Label tmp, "Log in with your own SiteBase login. Every change you make is saved under this name.", 0.6, 1.6, 10, 0.9

    SB_Label tmp, "Login", 0.6, 2.9, 3, 0.6
    Set ctl = CreateControl(tmp, acTextBox, acDetail, , , Cm(3.6), Cm(2.9), Cm(6), Cm(0.6))
    ctl.Name = "txtUser"

    SB_Label tmp, "Password", 0.6, 3.8, 3, 0.6
    Set ctl = CreateControl(tmp, acTextBox, acDetail, , , Cm(3.6), Cm(3.8), Cm(6), Cm(0.6))
    ctl.Name = "txtPassword"
    ctl.InputMask = "Password"

    Set ctl = SB_Button(tmp, "btnLogin", "Log in", "=SB_Login()", 3.6, 4.9, 3)
    ctl.Default = True
    SB_Button tmp, "btnExit", "Exit", "=SB_Exit()", 6.8, 4.9, 2.8

    SB_SaveForm tmp, "frmLogin"
    SB_SetStartupForm "frmLogin"
    MsgBox "frmLogin created and set as the start-up form." & vbCrLf & _
           "Open it, log in with your admin login, and choose Yes to build the screens.", vbInformation, "SiteBase"
End Sub

Public Sub SB_BuildAll()
    DoCmd.Hourglass True
    SysCmd acSysCmdSetStatus, "SiteBase: linking tables..."
    SB_LinkAll

    SysCmd acSysCmdSetStatus, "SiteBase: building screens..."
    SB_BuildDataScreens
    SB_BuildHome

    SysCmd acSysCmdClearStatus
    DoCmd.Hourglass False
    MsgBox "SiteBase screens are ready.", vbInformation, "SiteBase"
End Sub

'============================================================ linked tables
Public Sub SB_LinkAll()
    ' SQL Server object, local name in Access
    SB_Link "ref.Marketer", "ref_Marketer"
    SB_Link "ref.Season", "ref_Season"
    SB_Link "ref.Region", "ref_Region"
    SB_Link "ref.Packhouse", "ref_Packhouse"
    SB_Link "ref.Farm", "ref_Farm"
    SB_Link "ref.Commodity", "ref_Commodity"
    SB_Link "ref.VarietyGroup", "ref_VarietyGroup"
    SB_Link "ref.Variety", "ref_Variety"
    SB_Link "ref.Orchard", "ref_Orchard"
    SB_Link "ref.Pack", "ref_Pack"
    SB_Link "ref.TargetMarket", "ref_TargetMarket"
    SB_Link "ref.Gtin", "ref_Gtin"
    SB_Link "sec.AppUser", "sec_AppUser"
    SB_Link "ops.vw_DataProblems", "ops_DataProblems"
    SB_Link "ref.vw_OrchardDetail", "ref_OrchardDetail"
End Sub

Private Sub SB_Link(ByVal sqlName As String, ByVal localName As String)
    Dim db As DAO.Database, td As DAO.TableDef
    Set db = CurrentDb
    On Error Resume Next
    db.TableDefs.Delete localName
    On Error GoTo 0
    Set td = db.CreateTableDef(localName)
    td.Connect = SB_BaseConnect()
    td.SourceTableName = sqlName
    db.TableDefs.Append td
End Sub

'============================================================ data screens
Public Sub SB_BuildDataScreens()
    Const DEF_MKT As String = "=SB_DefaultMarketer()"
    Const DEF_SEASON As String = "=SB_CurrentSeason()"
    Const MKT_LIST As String = "SELECT MarketerID, MarketerCode & ' - ' & Name FROM ref_Marketer ORDER BY MarketerCode"
    Const COMMODITY_LIST As String = "SELECT CommodityCode, CommodityCode & ' - ' & Name FROM ref_Commodity ORDER BY CommodityCode"

    ' ---------------------------------------------------------------- Farms
    SB_DataScreen "frmFarms", "sfrmFarms", "Farms", "ref_Farm", "PUC", "Find PUC", Array( _
        "Marketer|MarketerID|C|" & MKT_LIST & "|" & DEF_MKT & "|3", _
        "PUC|PUC|T|||2", _
        "Farm name|Name|T|||5", _
        "PHC|PHC|T|||2", _
        "GGN|GGN|T|||3.2", _
        "GLN|GLN|T|||3.2", _
        "FLO ID|FloID|T|||2", _
        "Country|CountryCode|T|||1.6", _
        "Active|IsActive|B||True|1.4", _
        "Last changed by|ModifiedBy|L|||4", _
        "Last changed (UTC)|ModifiedAt|L|||3.5")

    ' ------------------------------------------------------------- Orchards
    SB_DataScreen "frmOrchards", "sfrmOrchards", "Orchards", "ref_Orchard", "", "", Array( _
        "Farm|FarmID|C|SELECT FarmID, PUC & ' - ' & Name FROM ref_Farm ORDER BY PUC||5", _
        "Season|SeasonID|C|SELECT SeasonID, SeasonCode FROM ref_Season ORDER BY SeasonCode DESC|" & DEF_SEASON & "|2", _
        "Orchard|OrchardCode|T|||2", _
        "Variety|VarietyID|C|SELECT VarietyID, VarietyCode & ' - ' & Name FROM ref_Variety WHERE IsActive = True ORDER BY VarietyCode||6", _
        "Licence 1|Licence1|T|||3", _
        "Licence 2|Licence2|T|||5", _
        "Mix orchard|IsMixOrchard|B||False|1.6", _
        "Active|IsActive|B||True|1.4", _
        "Last changed by|ModifiedBy|L|||4", _
        "Last changed (UTC)|ModifiedAt|L|||3.5"), _
        "Show farm", "FarmID", "SELECT FarmID, PUC & ' - ' & Name FROM ref_Farm ORDER BY PUC"

    ' ------------------------------------------------------------ Varieties
    SB_DataScreen "frmVarieties", "sfrmVarieties", "Varieties", "ref_Variety", "VarietyCode", "Find code", Array( _
        "Commodity|CommodityCode|C|" & COMMODITY_LIST & "|""GR""|2", _
        "Code|VarietyCode|T|||1.8", _
        "Variety name|Name|T|||5", _
        "Long name (label)|LongName|T|||8", _
        "Group|VarietyGroupID|C|SELECT VarietyGroupID, Name FROM ref_VarietyGroup ORDER BY Name||4", _
        "Mix|IsMix|B||False|1.2", _
        "Active|IsActive|B||True|1.4", _
        "Last changed by|ModifiedBy|L|||4", _
        "Last changed (UTC)|ModifiedAt|L|||3.5")

    ' ------------------------------------------------------- Variety groups
    SB_DataScreen "frmVarietyGroups", "sfrmVarietyGroups", "Variety groups", "ref_VarietyGroup", "", "", Array( _
        "Commodity|CommodityCode|C|" & COMMODITY_LIST & "|""GR""|2", _
        "Code|VarietyGroupCode|T|||1.8", _
        "Group name|Name|T|||5", _
        "Colour|Colour|V|White;Red;Black;Mixed||2", _
        "Last changed by|ModifiedBy|L|||4", _
        "Last changed (UTC)|ModifiedAt|L|||3.5")

    ' ---------------------------------------------------------------- Packs
    SB_DataScreen "frmPacks", "sfrmPacks", "Packs", "ref_Pack", "PackCode", "Find pack", Array( _
        "Commodity|CommodityCode|C|" & COMMODITY_LIST & "|""GR""|2", _
        "Pack code|PackCode|T|||2", _
        "Inner pack|InnerPack|T|||3", _
        "Net weight|NetWeight|T|||2.2", _
        "Last changed by|ModifiedBy|L|||4", _
        "Last changed (UTC)|ModifiedAt|L|||3.5")

    ' ---------------------------------------------------------------- GTINs
    SB_DataScreen "frmGtins", "sfrmGtins", "GTINs", "ref_Gtin", "GTIN", "Find GTIN", Array( _
        "Marketer|MarketerID|C|" & MKT_LIST & "|" & DEF_MKT & "|3", _
        "GTIN|GTIN|T|||3.4", _
        "Commodity|CommodityCode|C|" & COMMODITY_LIST & "|""GR""|1.8", _
        "Variety|VarietyCode|T|||1.6", _
        "Variety group|VarietyGroupCode|T|||1.8", _
        "Pack|PackCode|T|||1.6", _
        "Grade|Grade|T|||1.4", _
        "Mark|Mark|T|||1.8", _
        "Inventory|InventoryCode|T|||1.6", _
        "Size or count|SizeCount|T|||1.8", _
        "Country|CountryCode|T|||1.4", _
        "Active|IsActive|B||True|1.4", _
        "Last changed by|ModifiedBy|L|||4", _
        "Last changed (UTC)|ModifiedAt|L|||3.5")

    ' ------------------------------------------------- Data problems (read only)
    SB_DataScreen "frmProblems", "sfrmProblems", "Data problems (fix these before publishing)", "ops_DataProblems", "RecordKey", "Find", Array( _
        "Severity|Severity|L|||1.8", _
        "Check|RuleCode|L|||5", _
        "Table|TableName|L|||3", _
        "Record|RecordKey|L|||3.5", _
        "Problem|Message|L|||12"), _
        "", "", "", True

    ' --------------------------------------------- Admin: technicians (admin only)
    SB_DataScreen "frmAdmin", "sfrmAdmin", "Admin: technicians", "sec_AppUser", "", "", Array( _
        "Login|WindowsLogin|T|||4", _
        "Display name|DisplayName|T|||5", _
        "Role|Role|V|Admin;Technician;Viewer||2.5", _
        "Active|IsActive|B||True|1.4", _
        "Last changed by|ModifiedBy|L|||4", _
        "Last changed (UTC)|ModifiedAt|L|||3.5")
    SB_AddRecentChangesButton "frmAdmin"
End Sub

' Builds one screen: a datasheet (the list you edit) inside a window with
' Refresh / Who changed this? / Close buttons, an optional search box and an
' optional drop-down filter.
Private Sub SB_DataScreen(ByVal screenName As String, ByVal sheetName As String, ByVal title As String, _
                          ByVal recordSource As String, ByVal searchField As String, ByVal searchCaption As String, _
                          ByVal specs As Variant, _
                          Optional ByVal filterCaption As String = "", Optional ByVal filterField As String = "", _
                          Optional ByVal filterRowSource As String = "", Optional ByVal readOnly As Boolean = False)
    SB_BuildDatasheet sheetName, recordSource, specs, readOnly
    SB_BuildScreenWindow screenName, sheetName, title, searchField, searchCaption, _
                         filterCaption, filterField, filterRowSource, readOnly
End Sub

Private Sub SB_BuildDatasheet(ByVal sheetName As String, ByVal recordSource As String, _
                              ByVal specs As Variant, ByVal readOnly As Boolean)
    Dim frm As Form, tmp As String, ctl As Control, i As Integer, p() As String, topCm As Single

    SB_DeleteForm sheetName
    Set frm = CreateForm()
    tmp = frm.Name
    frm.RecordSource = recordSource
    frm.DefaultView = 2                       ' datasheet
    frm.AllowDatasheetView = True
    frm.AllowDeletions = False                ' deactivate (Active = No) instead of deleting
    If readOnly Then
        frm.AllowEdits = False
        frm.AllowAdditions = False
    End If
    frm.OnError = "[Event Procedure]"
    frm.HasModule = True
    frm.Module.InsertText _
        "Private Sub Form_Error(DataErr As Integer, Response As Integer)" & vbCrLf & _
        "    Response = SB_FormError(Me, DataErr)" & vbCrLf & _
        "End Sub" & vbCrLf

    topCm = 0.2
    For i = LBound(specs) To UBound(specs)
        p = Split(specs(i) & "|||||", "|")       ' Caption|Field|Kind|RowSource|Default|WidthCm
        Select Case p(2)
            Case "B"
                Set ctl = CreateControl(tmp, acCheckBox, acDetail, , p(1), Cm(4), Cm(topCm))
            Case "C", "V"
                Set ctl = CreateControl(tmp, acComboBox, acDetail, , p(1), Cm(4), Cm(topCm), Cm(5), Cm(0.6))
                If p(2) = "C" Then
                    ctl.RowSourceType = "Table/Query"
                    ctl.RowSource = p(3)
                    ctl.ColumnCount = 2
                    ctl.BoundColumn = 1
                    ctl.ColumnWidths = "0;" & Cm(7)
                    ctl.ListWidth = Cm(7.5)
                Else
                    ctl.RowSourceType = "Value List"
                    ctl.RowSource = p(3)
                    ctl.ColumnCount = 1
                End If
                ctl.LimitToList = True
            Case Else
                Set ctl = CreateControl(tmp, acTextBox, acDetail, , p(1), Cm(4), Cm(topCm), Cm(5), Cm(0.6))
                If p(2) = "L" Then
                    ctl.Locked = True
                    ctl.TabStop = False
                End If
        End Select
        ctl.Name = p(0)                          ' the datasheet column heading
        If p(4) <> "" Then ctl.DefaultValue = p(4)
        If Val(p(5)) > 0 Then ctl.ColumnWidth = Cm(Val(p(5)))
        topCm = topCm + 0.8
    Next i

    SB_SaveForm tmp, sheetName
End Sub

Private Sub SB_BuildScreenWindow(ByVal screenName As String, ByVal sheetName As String, ByVal title As String, _
                                 ByVal searchField As String, ByVal searchCaption As String, _
                                 ByVal filterCaption As String, ByVal filterField As String, _
                                 ByVal filterRowSource As String, ByVal readOnly As Boolean)
    Dim frm As Form, tmp As String, ctl As Control, x As Single
    Dim q As String
    q = """"

    SB_DeleteForm screenName
    Set frm = CreateForm()
    tmp = frm.Name
    SB_PlainForm frm, "SiteBase - " & title, 30, 17

    Set ctl = SB_Label(tmp, title, 0.5, 0.3, 18, 0.9)
    ctl.FontSize = 16: ctl.FontBold = True

    x = 0.5
    SB_Button tmp, "btnRefresh", "Refresh", "=SB_Refresh(" & q & screenName & q & ")", x, 1.4, 2.5: x = x + 2.7
    If Not readOnly Then
        SB_Button tmp, "btnHistory", "Who changed this?", "=SB_History(" & q & screenName & q & ")", x, 1.4, 4: x = x + 4.2
    End If
    SB_Button tmp, "btnClose", "Close", "=SB_CloseScreen(" & q & screenName & q & ")", x, 1.4, 2.2: x = x + 2.8

    If searchField <> "" Then
        SB_Label tmp, searchCaption, x, 1.5, 2.4, 0.6
        Set ctl = CreateControl(tmp, acTextBox, acDetail, , , Cm(x + 2.4), Cm(1.45), Cm(4), Cm(0.6))
        ctl.Name = "txtSearch"
        ctl.AfterUpdate = "=SB_Search(" & q & screenName & q & "," & q & searchField & q & "," & q & "txtSearch" & q & ")"
        x = x + 6.8
    End If

    If filterField <> "" Then
        SB_Label tmp, filterCaption, x, 1.5, 2.4, 0.6
        Set ctl = CreateControl(tmp, acComboBox, acDetail, , , Cm(x + 2.4), Cm(1.45), Cm(6), Cm(0.6))
        ctl.Name = "cboFilter"
        ctl.RowSourceType = "Table/Query"
        ctl.RowSource = filterRowSource
        ctl.ColumnCount = 2
        ctl.BoundColumn = 1
        ctl.ColumnWidths = "0;" & Cm(7)
        ctl.ListWidth = Cm(7.5)
        ctl.AfterUpdate = "=SB_FilterBy(" & q & screenName & q & "," & q & filterField & q & "," & q & "cboFilter" & q & ")"
    End If

    Set ctl = CreateControl(tmp, acSubform, acDetail, , , Cm(0.5), Cm(2.5), Cm(29), Cm(14))
    ctl.Name = "subData"
    ctl.SourceObject = sheetName

    SB_Label tmp, "Tip: click a row, then 'Who changed this?' to see its full history. " & _
                  "To retire a record, untick Active (records are never deleted).", 0.5, 16.6, 29, 0.6

    SB_SaveForm tmp, screenName
End Sub

Private Sub SB_AddRecentChangesButton(ByVal screenName As String)
    Dim ctl As Control
    DoCmd.OpenForm screenName, acDesign, , , , acHidden
    Set ctl = CreateControl(screenName, acCommandButton, acDetail, , , Cm(20), Cm(1.4), Cm(5), Cm(0.8))
    ctl.Name = "btnRecent"
    ctl.Caption = "Recent changes (everyone)"
    ctl.OnClick = "=SB_RecentChanges()"
    DoCmd.Close acForm, screenName, acSaveYes
End Sub

'============================================================ home
Public Sub SB_BuildHome()
    Dim frm As Form, tmp As String, ctl As Control, y As Single, i As Integer
    Dim items As Variant, p() As String, q As String
    q = """"

    SB_DeleteForm "frmHome"
    Set frm = CreateForm()
    tmp = frm.Name
    SB_PlainForm frm, "SiteBase", 14, 16
    frm.OnLoad = "=SB_HomeLoad()"

    Set ctl = SB_Label(tmp, "SiteBase", 0.8, 0.4, 10, 1.1)
    ctl.FontSize = 22: ctl.FontBold = True
    Set ctl = CreateControl(tmp, acTextBox, acDetail, , , Cm(0.8), Cm(1.6), Cm(12), Cm(0.6))
    ctl.Name = "txtWho"
    ctl.ControlSource = "=" & q & "Logged in as: " & q & " & SB_UserName()"
    ctl.Locked = True: ctl.TabStop = False: ctl.BorderStyle = 0

    items = Array("Farms|frmFarms", "Orchards|frmOrchards", "Varieties|frmVarieties", _
                  "Variety groups|frmVarietyGroups", "Packs|frmPacks", "GTINs|frmGtins", _
                  "Data problems|frmProblems")
    y = 2.8
    For i = LBound(items) To UBound(items)
        p = Split(items(i), "|")
        SB_Button tmp, "btn" & Mid$(p(1), 4), p(0), "=SB_Open(" & q & p(1) & q & ")", 0.8, y, 7, 1
        y = y + 1.3
    Next i

    SB_Button tmp, "btnAdmin", "Admin (technicians, recent changes)", "=SB_Open(" & q & "frmAdmin" & q & ")", 0.8, y + 0.4, 7, 1
    SB_Button tmp, "btnExit", "Exit", "=SB_Exit()", 0.8, y + 1.9, 3, 0.9

    SB_SaveForm tmp, "frmHome"
End Sub

'============================================================ small helpers
Private Function Cm(ByVal value As Single) As Long
    Cm = CLng(value * TWIPS_PER_CM)
End Function

Private Sub SB_PlainForm(frm As Form, ByVal caption As String, ByVal widthCm As Single, ByVal heightCm As Single)
    frm.Caption = caption
    frm.DefaultView = 0                       ' single form
    frm.RecordSelectors = False
    frm.NavigationButtons = False
    frm.DividingLines = False
    frm.ScrollBars = 0
    frm.AutoCenter = True
    frm.Width = Cm(widthCm)
    frm.Section(acDetail).Height = Cm(heightCm)
End Sub

Private Function SB_Label(ByVal formName As String, ByVal caption As String, _
                          ByVal leftCm As Single, ByVal topCm As Single, _
                          ByVal widthCm As Single, ByVal heightCm As Single) As Control
    Dim ctl As Control
    Set ctl = CreateControl(formName, acLabel, acDetail, , , Cm(leftCm), Cm(topCm), Cm(widthCm), Cm(heightCm))
    ctl.Caption = caption
    Set SB_Label = ctl
End Function

Private Function SB_Button(ByVal formName As String, ByVal ctlName As String, ByVal caption As String, _
                           ByVal onClick As String, ByVal leftCm As Single, ByVal topCm As Single, _
                           ByVal widthCm As Single, Optional ByVal heightCm As Single = 0.8) As Control
    Dim ctl As Control
    Set ctl = CreateControl(formName, acCommandButton, acDetail, , , Cm(leftCm), Cm(topCm), Cm(widthCm), Cm(heightCm))
    ctl.Name = ctlName
    ctl.Caption = caption
    ctl.OnClick = onClick
    Set SB_Button = ctl
End Function

Private Sub SB_SaveForm(ByVal tmpName As String, ByVal finalName As String)
    DoCmd.Close acForm, tmpName, acSaveYes
    DoCmd.Rename finalName, acForm, tmpName
End Sub

Private Sub SB_DeleteForm(ByVal formName As String)
    If SB_FormExists(formName) Then
        On Error Resume Next
        DoCmd.Close acForm, formName, acSaveNo
        DoCmd.DeleteObject acForm, formName
    End If
End Sub

Private Sub SB_SetStartupForm(ByVal formName As String)
    Dim db As DAO.Database, prp As DAO.Property
    Set db = CurrentDb
    On Error Resume Next
    db.Properties("StartupForm") = formName
    If Err.Number <> 0 Then
        Err.Clear
        Set prp = db.CreateProperty("StartupForm", dbText, formName)
        db.Properties.Append prp
    End If
End Sub
