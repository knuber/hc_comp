Option Explicit

Public x As New TheBigOne

Sub Determine_Active_Range()

    Dim r As range
    Dim s As String
    
    Set r = Selection

    MsgBox (r.Address)
    
    For Each cell In r
        s = s & cell.value
    Next cell
    
    MsgBox (s)

End Sub


Sub BackupPersonal()


  Application.DisplayAlerts = False
  With Workbooks("Personal.xlsb")
    .SaveCopyAs Workbooks("Personal.xlsb").Sheets("CONST").Cells(1, 2)
    .Save
  End With
  Application.DisplayAlerts = True
End Sub

Sub ExtractPNC_CSV()

    
    Dim x As New TheBigOne
    Dim f() As String
    Dim col() As String
    Dim coli As Long
    Dim bal() As String
    Dim bali As Long
    Dim sched_loan As String
    Dim p As FileDialog
    Dim i As Long
    Dim j As Long
    Dim m As Long
    Dim k As Long
    Dim row() As String
    Dim commit As Integer
    Dim oblig As Integer
    Dim sched As Integer
    Dim loan As Integer
    Dim wb As Workbook
    Dim sh1 As Worksheet
    Dim sh2 As Worksheet
    
    
    '--------Open file-------------
    Set p = Application.FileDialog(msoFileDialogOpen)
    p.Show
    '--------Extract text----------
    f = x.FILEp_GetTXT(p.SelectedItems(1), 2000)
    
    '--------resize arrays---------
    ReDim col(11, UBound(f, 2))
    ReDim bal(8, UBound(f, 2))
    coli = 1
    bali = 1
    j = 1
    m = 1
    
    '--------main interation-------
    For i = 0 To UBound(f, 2)
        sched = InStr(f(0, i), "Schedule")
        loan = InStr(f(0, i), "Loan")
        If sched <> 0 Then
            row = x.TXTp_ParseCSVrow(f, i + 2, 0)
            col(0, 0) = "Schedule#"
            For k = 0 To 10
                col(k + 1, 0) = row(k)
            Next k
            sched_loan = x.TXTp_ParseCSVrow(f, i + 1, 0)(0)
            i = i + 3
            commit = 0
            oblig = 0
            Do Until commit <> 0 Or oblig <> 0
                row = x.TXTp_ParseCSVrow(f, i, 0)
                col(0, j) = sched_loan
                For k = 0 To 10
                    col(k + 1, j) = row(k)
                Next k
                j = j + 1
                i = i + 1
                commit = InStr(f(0, i), "Commitment")
                oblig = InStr(f(0, i), "Oblig")
                '---or end of file-----
            Loop
            sched = 0
        ElseIf loan <> 0 Then
        
            row = x.TXTp_ParseCSVrow(f, i + 2, 0)
            bal(0, 0) = "Loan#"
            For k = 0 To 7
                bal(k + 1, 0) = row(k)
            Next k
            
            sched_loan = x.TXTp_ParseCSVrow(f, i + 1, 0)(0)
            i = i + 3
            commit = 0
            oblig = 0
            Do Until commit <> 0 Or oblig <> 0
                row = x.TXTp_ParseCSVrow(f, i, 0)
                bal(0, m) = sched_loan
                For k = 0 To 7
                    bal(k + 1, m) = row(k)
                Next k
                m = m + 1
                i = i + 1
                If i > UBound(f, 2) Then Exit Do
                If f(0, i) = "" Then Exit Do
                commit = InStr(f(0, i), "Commitment")
                oblig = InStr(f(0, i), "Oblig")
                '---or end of file-----
            Loop
            sched = 0
            loan = 0
        End If
    Next i
    
    Set wb = Workbooks.Add
    wb.Sheets.Add
    Set sh1 = wb.Sheets("Sheet1")
    Set sh2 = wb.Sheets("Sheet2")
    sh1.Name = "Collateral"
    sh2.Name = "Balance"
    
    Call x.SHTp_Dump(col, sh1.Name, 1, 1, True, True, 1, 4, 5, 6, 7, 8, 9, 10, 11)
    Call x.SHTp_Dump(bal, sh2.Name, 1, 1, True, True, 1, 2, 5, 6, 7, 8)
    
    sh1.range("A1").CurrentRegion.Columns.AutoFit
    sh2.range("A2").CurrentRegion.Columns.AutoFit
    
    
End Sub


Sub GrabBorrowHist()
    
    Dim sh As Worksheet
    Dim x As New TheBigOne
    Dim i As Long
    Dim b() As String
    Set sh = Application.ActiveSheet
    
    b = x.SHTp_Get(sh.Name, 3, 1, True)
    Call x.TBLp_FilterSingle(b, 14, "", False)
    Call x.TBLp_DeleteCols(b, x.ARRAYp_MakeInteger(6, 7, 8, 9, 10, 11, 12, 13))
    Call x.TBLp_AddEmptyCol(b)
    Call x.TBLp_AddEmptyCol(b)
    For i = 1 To UBound(b, 2)
        b(9, i) = ActiveSheet.Name
        b(10, i) = ActiveWorkbook.Name
    Next i
    b(9, 0) = "Tab"
    b(10, 0) = "File"
    
    Application.Workbooks("PERSONAL.XLSB").Activate
    Set sh = Application.Workbooks("PERSONAL.XLSB").Sheets("BORROW")
    i = 1
    Do Until sh.Cells(i, 1) = ""
        i = i + 1
    Loop
    Call x.SHTp_Dump(b, "BORROW", i, 1, False, True)

End Sub

Function fn_coln_colchar(colnum As Long) As String
    
    fn_coln_colchar = colnum / 26
    
End Function

Sub add_quote_front()

    Dim r As range
    Set r = Selection
    Dim c As Object
    
    For Each c In r.Cells
        If c.value <> "" Then c.value = "'" & c.value
    Next c
    

End Sub

Function json_from_list(keys As range, values As range) As String

    Dim json As String
    Dim i As Integer
    Dim first_comma As Boolean
    Dim needs_braces As Integer
    
    needs_comma = False
    needs_braces = 0
    
    For i = 1 To keys.Cells.Count
        If values.Cells(i).value <> "" Then
            needs_braces = needs_braces + 1
            If needs_comma Then json = json & ","
            needs_comma = True
            If IsNumeric(values.Cells(i).value) Then
                json = json & Chr(34) & keys.Cells(i).value & Chr(34) & ":" & values.Cells(i).value
            Else
                json = json & Chr(34) & keys.Cells(i).value & Chr(34) & ":" & Chr(34) & values.Cells(i).value & Chr(34)
            End If
        End If
    Next i
    
    If needs_braces > 0 Then json = "{" & json & "}"
    
    json_from_list = json

End Function

Function json_concat(list As range) As String
    
        Dim json As String
        Dim i As Integer
        
        i = 0

        For Each cell In list
            If cell.value <> "" Then
                i = i + 1
                If i = 1 Then
                    json = cell.value
                Else
                    json = json & "," & cell.value
                End If
            End If
        Next cell
        
        If i > 1 Then json = "[" & json & "]"
        json_concat = json

End Function


Sub json_from_table_pretty()
    
    Dim wapi As New Windows_API
    
    Dim tbl() As Variant
    
    tbl = Selection
    
    Dim ajson As String
    Dim json As String
    Dim r As Integer
    Dim c As Integer
    Dim needs_comma As Boolean
    Dim needs_braces As Integer
    
    needs_comma = False
    needs_braces = 0
    ajson = ""
    
    For r = 2 To UBound(tbl, 1)
        For c = 1 To UBound(tbl, 2)
            If tbl(r, c) <> "" Then
                needs_braces = needs_braces + 1
                If needs_comma Then json = json & "," & vbCrLf
                needs_comma = True
                If IsNumeric(tbl(r, c)) Then
                    json = json & Chr(34) & tbl(1, c) & Chr(34) & ":" & tbl(r, c)
                Else
                    json = json & Chr(34) & tbl(1, c) & Chr(34) & ":" & Chr(34) & tbl(r, c) & Chr(34)
                End If
            End If
        Next c
        If needs_braces > 0 Then json = "{" & vbCrLf & json & vbCrLf & "}"
        needs_comma = False
        needs_braces = 0
        If r > 2 Then
            ajson = ajson & vbCrLf & "," & vbCrLf & json
        Else
            ajson = json
        End If
        json = ""
    Next r
    
    If r > 2 Then ajson = "[" & ajson & "]"
    
      
    Call wapi.ClipBoard_SetData(ajson)

End Sub

Sub json_from_table()
    
    Dim wapi As New Windows_API
    
    Dim tbl() As Variant
    
    tbl = Selection
    
    Dim ajson As String
    Dim json As String
    Dim r As Integer
    Dim c As Integer
    Dim needs_comma As Boolean
    Dim needs_braces As Integer
    
    needs_comma = False
    needs_braces = 0
    ajson = ""
    
    For r = 2 To UBound(tbl, 1)
        For c = 1 To UBound(tbl, 2)
            If tbl(r, c) <> "" Then
                needs_braces = needs_braces + 1
                If needs_comma Then json = json & ","
                needs_comma = True
                If IsNumeric(tbl(r, c)) And Mid(tbl(r, c), 1, 1) <> 0 Then
                    json = json & Chr(34) & tbl(1, c) & Chr(34) & ":" & tbl(r, c)
                Else
                    json = json & Chr(34) & tbl(1, c) & Chr(34) & ":" & Chr(34) & tbl(r, c) & Chr(34)
                End If
            End If
        Next c
        If needs_braces > 0 Then json = "{" & json & "}"
        needs_comma = False
        needs_braces = 0
        If r > 2 Then
            ajson = ajson & "," & json
        Else
            ajson = json
        End If
        json = ""
    Next r
    
    If r > 2 Then ajson = "[" & ajson & "]"
    
      
    Call wapi.ClipBoard_SetData(ajson)

End Sub

Sub PastValues()

On Error GoTo errh

    Call Selection.PasteSpecial(xlPasteValues, xlNone, False, False)
    
errh:

    
End Sub

Sub CollapsePvtItem()

On Error GoTo show_det
    ActiveCell.PivotItem.DrilledDown = False
    
On Error GoTo drill_down
    ActiveCell.PivotItem.ShowDetail = False



show_det:

    If Err.Number <> 0 Then
        On Error GoTo errh
        ActiveCell.PivotItem.ShowDetail = False
        Err.Number = 0
    End If
drill_down:
    If Err.Number <> 0 Then
        On Error GoTo errh
        ActiveCell.PivotItem.DrilledDown = False
    End If
errh:


End Sub

Sub ExpandPvtItem()

On Error GoTo show_det
    ActiveCell.PivotItem.DrilledDown = True
    
On Error GoTo drill_down
    ActiveCell.PivotItem.ShowDetail = True


show_det:

    If Err.Number <> 0 Then
        On Error GoTo errh
        ActiveCell.PivotItem.ShowDetail = True
        Err.Number = 0
    End If
drill_down:
On Error GoTo errh
    If Err.Number <> 0 Then
        On Error GoTo errh
        ActiveCell.PivotItem.DrilledDown = True
    End If

errh:

End Sub

Sub CollapsePvtFld()

On Error GoTo show_det
    ActiveCell.PivotField.DrilledDown = False
    
On Error GoTo drill_down
    ActiveCell.PivotField.ShowDetail = False



show_det:

    If Err.Number <> 0 Then
        On Error GoTo errh
        ActiveCell.PivotField.ShowDetail = False
        Err.Number = 0
    End If
drill_down:
On Error GoTo errh
    If Err.Number <> 0 Then
        On Error GoTo errh
        ActiveCell.PivotField.DrilledDown = False
    End If

errh:

End Sub

Sub ExpandPvtFld()

On Error GoTo show_det
    ActiveCell.PivotField.DrilledDown = True
    
On Error GoTo drill_down
    ActiveCell.PivotField.ShowDetail = True


show_det:

    If Err.Number <> 0 Then
        On Error GoTo errh
        ActiveCell.PivotField.ShowDetail = True
        Err.Number = 0
    End If
drill_down:
    If Err.Number <> 0 Then
        On Error GoTo errh
        ActiveCell.PivotField.DrilledDown = True
    End If
    
errh:

End Sub

Sub ColorMatrixExtract()

    Dim s() As String
    Dim t() As String
    
    Dim i As Long
    Dim j As Long
    Dim k As Long
    Dim m As Long
    Dim sh As Worksheet
    Dim found As Boolean
    
    ReDim s(1, 10000)
    For Each sh In Sheets
        If sh.Name = "Color Matrix" Then found = True
    Next sh
    If Not found Then Exit Sub
    Set sh = Sheets("Color Matrix")
    If sh.Cells(5, 1) <> "BASE WHITE" Then Exit Sub
    m = 1
    i = 1
    s(0, 0) = "COLOR ID"
    s(1, 0) = "DESCRIPTION"
    
    
    
    Do
        If sh.Cells(6, i) = "COLOR ID" Then
            j = 1
            Do Until sh.Cells(6, i + j) = "DESCRIPTION"
                j = j + 1
            Loop
            k = 7
            Do Until sh.Cells(k, i) = ""
                s(0, m) = sh.Cells(k, i)
                s(1, m) = sh.Cells(k, i + j)
                k = k + 1
                m = m + 1
            Loop
        End If
        i = i + 1
        If i = 500 Then Exit Do
    Loop
    
    ReDim Preserve s(1, m - 1)
    
    Call x.SHTp_Dump(s, "Extract", 1, 1, True, True)

End Sub


