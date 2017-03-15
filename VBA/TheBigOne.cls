Option Explicit

Private ADOo_con() As ADODB.Connection
Private ADOo_rs() As ADODB.Recordset
Public ADOo_errstring As String

Public Enum ADOinterface
    MicrosoftJetOLEDB4 = 0
    MicrosoftACEOLEDB12 = 1
    SQLServer = 2
    SQLServerNativeClient = 3
    SQLServerNativeClient10 = 4
    OracleODBC = 5
    OracleOLEDB = 6
    TextFile = 7
    ISeries = 8
End Enum


Public Function TBLp_Aggregate(ByRef tbl() As String, ByRef needsort As Boolean, ByRef headers As Boolean, ByRef del_unused As Boolean, ParamArray groupnum_type_sumnum()) As Boolean
    
    Dim i As Long
    Dim j As Long
    Dim nt() As String
    Dim keep() As Integer
    
    If needsort Then
        If Not TBLp_BubbleSortAsc(tbl, Me.PAp_2DGetIntegerArray(0, groupnum_type_sumnum), Me.PAp_2DGetStringArray(1, groupnum_type_sumnum), headers) Then
            TBLp_Aggregate = False
            Exit Function
        End If
    End If
    
    If Not TBLp_Roll(tbl, Me.PAp_2DGetIntegerArray(0, groupnum_type_sumnum), Me.PAp_2DGetIntegerArray(2, groupnum_type_sumnum), headers) Then
        TBLp_Aggregate = False
        Exit Function
    End If
        
    
    If del_unused Then
        keep = Me.PAp_2DGetMultIntegerArray(Me.ARRAYp_MakeInteger(0, 2), groupnum_type_sumnum)
        ReDim nt(UBound(keep()), UBound(tbl, 2))
        For i = 0 To UBound(keep())
            For j = 0 To UBound(tbl, 2)
                nt(i, j) = tbl(keep(i), j)
            Next j
        Next i
        tbl = nt
    End If
    
    
    
    TBLp_Aggregate = True

End Function


Function TBLp_BubbleSortAsc(ByRef tbl() As String, ByRef sortflds() As Integer, ByRef typeflds() As String, ByRef headers As Boolean) As Boolean
    
On Error GoTo errh
    'get fort field numbers
    'loop through each row and generate the row key
    'eveluate the row key against other row keys
    'perform swaps
    
    Dim i As Long
    Dim j As Long
    Dim k As Long
    
    k = 0
    If headers Then k = 1
    
    For i = k To UBound(tbl, 2) - 1
        For j = i + 1 To UBound(tbl, 2)
            If ROWe_AscSwapFlag(tbl, i, j, sortflds, typeflds) Then
                Call ROWp_Swap(tbl, i, j)
            Else
                If Me.ADOo_errstring <> "" Then
                    TBLp_BubbleSortAsc = False
                    Exit Function
                End If
            End If
        Next j
    Next i

errh:
    If Err.Number <> 0 Then
        MsgBox ("Error at TBLP_BubbleSortAsc." & vbCrLf & Err.Description)
        Me.ADOo_errstring = Err.Description
    End If
    
    TBLp_BubbleSortAsc = True
        

End Function

Function TBLp_KeyBubbleSortAsc(ByRef tbl() As String, ByRef sortflds() As Integer, ByRef headers As Boolean) As Boolean
    
On Error GoTo errh
    'get fort field numbers
    'loop through each row and generate the row key
    'eveluate the row key against other row keys
    'perform swaps
    
    Dim i As Long
    Dim j As Long
    Dim k As Long
    
    k = 0
    If headers Then k = 1
    
    For i = k To UBound(tbl, 2) - 1
        For j = i + 1 To UBound(tbl, 2)
            If ROWe_KeyAscSwapFlag(tbl, i, j, sortflds) Then
                Call ROWp_Swap(tbl, i, j)
            Else
                If Me.ADOo_errstring <> "" Then
                    TBLp_KeyBubbleSortAsc = False
                    Exit Function
                End If
            End If
        Next j
    Next i

errh:
    If Err.Number <> 0 Then
        MsgBox ("Error at TBLP_keyBubbleSortAsc." & vbCrLf & Err.Description)
        Me.ADOo_errstring = Err.Description
    End If
    
    TBLp_KeyBubbleSortAsc = True
        

End Function

Sub TBLp_BubbleSortDescend(ByRef tbl() As String, ByRef sortflds() As Integer, ByRef typeflds() As String, ByRef headers As Boolean)
    
    'get fort field numbers
    'loop through each row and generate the row key
    'eveluate the row key against other row keys
    'perform swaps
    
    Dim i As Long
    Dim j As Long
    Dim k As Long
    
    k = 0
    If headers Then k = 1
    
    For i = k To UBound(tbl, 2) - 1
        For j = i + 1 To UBound(tbl, 2)
            If ROWe_DescendSwapFlag(tbl, i, j, sortflds, typeflds) Then
                Call ROWp_Swap(tbl, i, j)
            End If
        Next j
    Next i

End Sub


Public Function TBLp_Roll(ByRef tbl() As String, ByRef gflds() As Integer, ByRef sflds() As Integer, ByRef headers As Boolean) As Boolean

On Error GoTo errh
    Dim i As Long 'indexes primary row
    Dim j As Long 'indexes secondary chaecker row
    Dim k As Integer 'used to start at 0 or 1
    Dim m As Long 'used to aggregate on sequencing lines (i and j aggregate to m line) then shorten array to m length - 1
    
    k = 0
    If headers Then k = 1
    m = k
    For i = k To UBound(tbl, 2)
        If i = UBound(tbl, 2) Then
            i = i
        End If
        j = i + 1
        Do
            If j > UBound(tbl, 2) Then Exit Do
            If ROWe_MatchesFlag(tbl, i, j, gflds) Then
                Call ROWp_Aggregate2Rows(tbl, i, j, sflds)
            Else
                Exit Do
            End If
            j = j + 1
            If j > UBound(tbl, 2) Then
                Exit Do
            End If
        Loop
        Call ROWp_Copy(tbl, i, m)
        m = m + 1
        i = j - 1
    Next i
    
    ReDim Preserve tbl(UBound(tbl, 1), m - 1)

errh:
    If Err.Number <> 0 Then
        Me.ADOo_errstring = Err.Description
        TBLp_Roll = False
        Exit Function
    End If
    
    TBLp_Roll = True
    

End Function


Sub ROWp_Swap(ByRef tbl() As String, ByRef p1 As Long, ByRef p2 As Long)
    
    Dim temprow() As String
    ReDim temprow(UBound(tbl, 1))
    Dim i As Integer
    
    For i = 0 To UBound(tbl, 1)
        temprow(i) = tbl(i, p2)
    Next i
    
    For i = 0 To UBound(tbl, 1)
        tbl(i, p2) = tbl(i, p1)
    Next i
    
    For i = 0 To UBound(tbl, 1)
        tbl(i, p1) = temprow(i)
    Next i
    
End Sub

Sub ROWp_Copy(ByRef tbl() As String, ByRef r_from As Long, ByRef r_to As Long)
    
    Dim i As Integer
    
    For i = 0 To UBound(tbl, 1)
        tbl(i, r_to) = tbl(i, r_from)
    Next i
    
End Sub

Sub ROWp_Aggregate2Rows(ByRef tbl() As String, ByRef p1 As Long, ByRef p2 As Long, ByRef sflds() As Integer)
    
    Dim i As Integer
    On Error GoTo exitsub
    For i = 0 To UBound(sflds, 1)
        tbl(sflds(i), p1) = CDbl(tbl(sflds(i), p1)) + CDbl(tbl(sflds(i), p2))
    Next i
    
exitsub:
    
End Sub



Function ROWe_AscSwapFlag(ByRef tbl() As String, ByRef row1 As Long, ByRef row2 As Long, ByRef KeyFld() As Integer, ByRef TypeFld() As String) As Boolean
    'only returns true if greater than
    
On Error GoTo errh
    Dim i As Integer
    Dim compare As Integer
    
    For i = 0 To UBound(KeyFld)
        Select Case TypeFld(i)
            Case "S"
                compare = Me.MISCe_CompareString(CStr(tbl(KeyFld(i), row1)), CStr(tbl(KeyFld(i), row2)))
            Case "N"
                compare = Me.MISCe_CompareDouble(CDbl(tbl(KeyFld(i), row1)), CDbl(tbl(KeyFld(i), row2)))
            Case "D"
                compare = Me.MISCe_CompareDate(CDate(tbl(KeyFld(i), row1)), CDate(tbl(KeyFld(i), row2)))
        End Select
        Select Case compare
            Case -1
                ROWe_AscSwapFlag = True
                Exit Function
            Case 1
                ROWe_AscSwapFlag = False
                Exit Function
        End Select
    Next i
    
errh:
    If Err.Number <> 0 Then
        MsgBox ("Error at ROWe_AscSwapFlag." & vbCrLf & Err.Description)
        Me.ADOo_errstring = Err.Description
        Exit Function
    End If

End Function

Function ROWe_KeyAscSwapFlag(ByRef tbl() As String, ByRef row1 As Long, ByRef row2 As Long, ByRef KeyFld() As Integer) As Boolean
    'only returns true if greater than
    
On Error GoTo errh
    Dim i As Integer
    Dim compare As Integer
    Dim key1 As String
    Dim key2 As String
    
    For i = 0 To UBound(KeyFld)
        key1 = key1 & tbl(KeyFld(i), row1)
        key2 = key2 & tbl(KeyFld(i), row2)
    Next i
        
    compare = Me.MISCe_CompareString(key1, key2)
          
    Select Case compare
        Case -1
            ROWe_KeyAscSwapFlag = True
            Exit Function
        Case 1
            ROWe_KeyAscSwapFlag = False
            Exit Function
    End Select

    
errh:
    If Err.Number <> 0 Then
        MsgBox ("Error at ROWe_keyAscSwapFlag." & vbCrLf & Err.Description)
        Me.ADOo_errstring = Err.Description
        Exit Function
    End If

End Function

Function ROWe_DescendSwapFlag(ByRef tbl() As String, ByRef row1 As Long, ByRef row2 As Long, ByRef KeyFld() As Integer, ByRef TypeFld() As String) As Boolean
    'only returns true if greater than
    
    Dim i As Integer
    Dim compare As Integer
    
    For i = 0 To UBound(KeyFld)
        Select Case TypeFld(i)
            Case "S"
                compare = Me.MISCe_CompareString(CStr(tbl(KeyFld(i), row1)), CStr(tbl(KeyFld(i), row2)))
            Case "N"
                compare = Me.MISCe_CompareDouble(CDbl(tbl(KeyFld(i), row1)), CDbl(tbl(KeyFld(i), row2)))
            Case "D"
                compare = Me.MISCe_CompareDate(CDate(tbl(KeyFld(i), row1)), CDate(tbl(KeyFld(i), row2)))
        End Select
        Select Case compare
            Case 1
                ROWe_DescendSwapFlag = True
                Exit Function
            Case -1
                ROWe_DescendSwapFlag = False
                Exit Function
        End Select
    Next i

End Function

Function ROWe_MatchesFlag(ByRef tbl() As String, ByRef row1 As Long, ByRef row2 As Long, ByRef KeyFld() As Integer) As Boolean
    'only returns true if greater than
    
    Dim i As Integer
    Dim k1 As String
    Dim k2 As String
    
    For i = 0 To UBound(KeyFld())
        k1 = k1 & tbl(KeyFld(i), row1)
    Next i
    
    For i = 0 To UBound(KeyFld())
        k2 = k2 & tbl(KeyFld(i), row2)
    Next i
    
    
    If k2 = k1 Then
        ROWe_MatchesFlag = True
    Else
        ROWe_MatchesFlag = False
    End If
    

End Function

Sub SHTp_Dump(ByRef tbl() As String, ByRef sheet As String, ByRef row As Long, ByRef col As Long, ByRef clear As Boolean, ByRef transpose As Boolean, ParamArray NumFields())

    Dim sh As Worksheet
    Set sh = Sheets(sheet)
    
    If clear Then sh.Cells.clear
    If transpose Then Call Me.ARRAYp_Transpose(tbl)
    
    sh.range(sh.Cells(row, col).Address & ":" & sh.Cells(row + UBound(tbl, 1), col + UBound(tbl, 2)).Address).FormulaR1C1 = tbl
    
    On Error GoTo errhndl

    If UBound(NumFields()) <> -1 Then
        Dim i As Integer
        i = 0
        For i = 0 To UBound(NumFields())
            Call sh.Columns(NumFields(i) + 1).TextToColumns
        Next i
    End If
    
errhndl:
    If Err.Number <> 0 Then MsgBox ("Error in dumping to sheet" & vbCrLf & Err.Description)
    

End Sub

Sub ARRAYp_Transpose(ByRef a() As String)

    Dim s() As String
    ReDim s(UBound(a, 2), UBound(a, 1))
    
    Dim i As Long
    Dim j As Long
    
    For i = 0 To UBound(s, 1)
        For j = 0 To UBound(s, 2)
            s(i, j) = a(j, i)
        Next j
    Next i

    a = s

End Sub


Public Function SHTp_Get(ByRef sheet As String, ByRef row As Long, ByRef col As Long, ByRef headers As Boolean) As String()

    Dim i As Long
    Dim j As Long
    Dim table() As String
    Dim sh As Worksheet
    Set sh = Sheets(sheet)
    
    On Error GoTo errhdnl
    
    i = 1
    While sh.Cells(row, col + i - 1) <> ""
        i = i + 1
    Wend
    
    j = 1
    While sh.Cells(row + j - 1, col) <> ""
        j = j + 1
    Wend
    
    ReDim table(i - 2, j - 2)
    i = 1
    While i <= UBound(table, 1) + 1
        j = 0
        While j <= UBound(table, 2)
            table(i - 1, j) = sh.Cells(row + j, col + i - 1)
            j = j + 1
        Wend
        i = i + 1
    Wend
    
errhdnl:
    If Err.Number <> 0 Then
        MsgBox (Err.Description)
    End If
    
    SHTp_Get = table

End Function

Public Sub TBLp_FilterSingle(ByRef table() As String, ByRef column As Long, ByVal Filter As String, ByVal Equals As Boolean)


    Dim i As Long
    Dim j As Long
    Dim m As Long
    
    j = 0
    i = 1
    While i <= UBound(table, 2)
        If (table(column, i) = Filter) = Equals Then
            j = j + 1
            m = 0
            While m <= UBound(table, 1)
                table(m, j) = table(m, i)
                m = m + 1
            Wend
        End If
        i = i + 1
    Wend
    
    ReDim Preserve table(UBound(table, 1), j)
    
End Sub

Sub TBLp_AddEmptyCol(ByRef table() As String)

    Dim i As Long
    Dim j As Long
    Dim temp() As String
    ReDim temp(UBound(table, 1) + 1, UBound(table, 2))
    i = 0
    While i <= UBound(table, 1)
        j = 0
        While j <= UBound(table, 2)
            temp(i, j) = table(i, j)
            j = j + 1
        Wend
        i = i + 1
    Wend
    
    table() = temp()
    
    

End Sub

Function SQLp_RollingMonthList(ByRef mmmyy As String, ByRef outformat As String, ByRef monthcount As Integer) As String
    

    Dim cy As String
    Dim cmn As Integer
    Dim mlist As String
    
    Dim i As Integer
    
    cmn = Format(DateValue(Left(mmmyy, 3) & "-01-" & Right(mmmyy, 2)), "m")
    cy = Right(mmmyy, 2)
    
    For i = 0 To monthcount - 1
        If i <> 0 Then mlist = mlist & ","
        mlist = mlist & "'" & UCase(Format(DateValue(cmn & "-01-" & cy), outformat)) & "'"
        cmn = cmn - 1
        If cmn = 0 Then
            cmn = 12
            cy = Format(CInt(cy) - 1, "00")
        End If
    Next i
    SQLp_RollingMonthList = mlist
    
    
End Function

Sub TBLp_DeleteCols(ByRef tbl() As String, ByRef column() As Integer)
    
    Dim temp() As String
    ReDim temp(UBound(tbl, 1) - (UBound(column()) + 1), UBound(tbl, 2))
    Dim i As Long
    Dim j As Long
    Dim m As Long
    Dim k As Long
    Dim OK As Boolean
    
    m = -1
    i = 0
    While i <= UBound(tbl, 1)
        k = 0
        OK = True
        Do While k <= UBound(column())
            If i = column(k) Then
                OK = False
                Exit Do
            End If
            k = k + 1
        Loop
        If OK = True Then
            m = m + 1
            j = 0
            While j <= UBound(tbl, 2)
                temp(m, j) = tbl(i, j)
                j = j + 1
            Wend
        End If
        i = i + 1
    Wend
    
    tbl() = temp()
End Sub



Public Function ADOp_OpenCon(ByRef con As Integer, Optional ByVal value As ADOinterface, Optional ConnectTo As String, Optional IntgrtdSec As Boolean, Optional UserName As String, Optional Password As String, Optional textconfigs As String) As Boolean

On Error GoTo ConnectionProblem
    
    Dim itype As String
    Dim interface As String
    Dim stype As String
    Dim source As String
    Dim properties As String
    Dim cs As String
    
    If ADOo_con(con) Is Nothing Then
        Set ADOo_con(con) = New ADODB.Connection
    End If
    'if the connection is not open the set the provider if it is supplied
    If ADOo_con(con).State = 0 Then
        Select Case value
            Case 0
                interface = "Microsoft.Jet.OLEDB.4.0"
                itype = "Provider="
                source = ConnectTo
                stype = ";Data Source="
                If IntgrtdSec Then
                    properties = ";User ID=admin"
                    properties = properties & ";Password="
                Else
                    properties = ";User ID=" & UserName
                    properties = properties & ";Password=" & Password
                End If
            Case 1
                interface = "Microsoft.ACE.OLEDB.12.0"
                itype = "Provider="
                source = ConnectTo
                stype = ";Data Source="
                If IntgrtdSec Then
                    properties = ";Persist Security Info = False"
                Else
                    properties = ";Jet OLEDB:Database Password=" & Password
                End If
            Case 2
                interface = "SQLOLEDB"
                itype = "Provider="
                source = ConnectTo
                stype = ";Data Source="
                If IntgrtdSec Then
                    properties = ";Integrated Security=SSPI"
                Else
                    properties = ";User ID=" & UserName
                    properties = properties & ";Password=" & Password
                End If
            Case 3
                interface = "SQLNCLI"
                itype = "Provider="
                source = ConnectTo
                stype = ";Server="
                If IntgrtdSec Then
                    properties = ";Trusted_Connection=yes"
                Else
                    properties = ";Uid=" & UserName
                    properties = properties & ";Pwd=" & Password
                End If
            Case 4
                interface = "SQLNCLI10"
                itype = "Provider="
                source = ConnectTo
                stype = ";Server="
                If IntgrtdSec Then
                    properties = ";Trusted_Connection=yes"
                Else
                    properties = ";Uid=" & UserName
                    properties = properties & ";Pwd=" & Password
                End If
            Case 5
                interface = "{Microsoft ODBC for Oracle}"
                itype = "Driver="
                source = ConnectTo
                stype = ";Server="
                properties = ";Uid=" & UserName
                properties = properties & ";Pwd=" & Password
            Case 6
                interface = "OraOLEDB.Oracle"
                itype = "Provider="
                source = ConnectTo
                stype = ";Data Source="
                If IntgrtdSec Then
                    properties = ";OSAuthent=1"
                Else
                    properties = ";User ID=" & UserName
                    properties = properties & ";Password=" & Password
                End If
            Case 7
                interface = "Microsoft.Jet.OLEDB.4.0"
                itype = "Provider="
                source = ConnectTo
                stype = ";Data Source="
                properties = properties & ";" & textconfigs
                'text;HDR=yes;FMT=Delimited as example
            Case 8
                interface = "{iSeries Access ODBC Driver}"
                itype = "Driver="
                source = ConnectTo
                stype = ";System="
                properties = ";Uid=" & UserName
                properties = properties & ";Pwd=" & Password
                
        End Select
    
        cs = itype & interface & stype & source & properties
        ADOo_con(con).Open (cs)
        
    End If
    
       
ConnectionProblem:
    If Err.Number <> 0 Then
        ADOo_errstring = "Error Number:" & Err.Number & " -" & Err.Description
        ADOp_OpenCon = False
    Else
        ADOo_errstring = ""
        ADOp_OpenCon = True
    End If
    
'this path is only used if there are no connection strings available
noconnectionstring:
        
End Function

Private Sub Class_Initialize()

    ReDim ADOo_con(9)
    ReDim ADOo_rs(9)

End Sub

Public Function ADOp_MoveRecords(ByRef con_from As Integer, ByRef con_to As Integer, ByRef from_sql As String, ByRef to_table As String, ByRef trim As Boolean) As Boolean
    
On Error GoTo err_inactive
    
    Dim i As Long
    Dim rc As Long
    
'---------------------------Make sure connections are good to go------------------------------------------------------

    If ADOo_con(con_from) Is Nothing Then Set ADOo_con(con_from) = New ADODB.Connection
    If ADOo_con(con_to) Is Nothing Then Set ADOo_con(con_to) = New ADODB.Connection
    
    If ADOo_con(con_from).State = 0 Then
        ADOo_errstring = "'From' source not connected in MoveRecords operation"
        ADOp_MoveRecords = False
        Exit Function
    End If
    
    If ADOo_con(con_to).State = 0 Then
        ADOo_errstring = "'To' source not connected in MoveRecords operation"
        ADOp_MoveRecords = False
        Exit Function
    End If
    
    

'-------------Start by opening a record set on the source location statement-----------------------------
    
    ADOo_con(con_from).CommandTimeout = 600
    Set ADOo_rs(con_from) = ADOo_con(con_from).Execute(from_sql)
    
On Error GoTo err_active

'---------------get first recordset that has >0 column count--------------------

    If ADOo_rs(con_from).Fields.Count = 0 Then
        Do Until ADOo_rs(con_from).Fields.Count <> 0
            Set ADOo_rs(con_from) = ADOo_rs(con_from).NextRecordset()
            If ADOo_rs(con_from) Is Nothing Then Exit Do
        Loop
        
        If ADOo_rs(con_from) Is Nothing Then
            ADOo_errstring = "SQL did not return any results in MoveRecords Finction"
            ADOp_MoveRecords = False
            Exit Function
        End If
    End If
    
    
    
'---------------Open up destination table----------------------------------
    
    If ADOo_rs(con_to) Is Nothing Then
        Set ADOo_rs(con_to) = New ADODB.Recordset
    End If
    
    If ADOo_rs(con_to).State = 1 Then
        ADOo_rs(con_to).Close
    End If
    
    Call ADOo_rs(con_to).Open(to_table, ADOo_con(con_to), adOpenDynamic, adLockPessimistic)

'-------------Make sure number of fields same in both record sets--------------------

    If ADOo_rs(con_to).Fields.Count <> ADOo_rs(con_from).Fields.Count Then
        ADOo_errstring = "Field count in MoveRecords function not equal"
        ADOp_MoveRecords = False
        Exit Function
    End If
    
'--------------Start movement-------------------------
    
    ADOo_con(con_to).BeginTrans
    
    
    
    While ADOo_rs(con_from).EOF = False
        rc = rc + 1
        ADOo_rs(con_to).AddNew
        For i = 0 To ADOo_rs(con_from).Fields.Count - 1
            If IsNull(ADOo_rs(con_from).Fields(i)) Then
                ADOo_rs(con_to).Fields(i) = ""
            Else
                If trim Then
                    ADOo_rs(con_to).Fields(i) = LTrim(RTrim(ADOo_rs(con_from).Fields(i)))
                Else
                    ADOo_rs(con_to).Fields(i) = ADOo_rs(con_from).Fields(i)
                End If
            End If
        Next i
        ADOo_rs(con_to).Update
        ADOo_rs(con_from).MoveNext
    Wend
    
    ADOo_con(con_to).CommitTrans
    
'---------------- close connections------------------

    ADOo_rs(con_to).Close
    ADOo_rs(con_from).Close
    
'--------------error handling---------------------------

err_inactive:
    If Err.Number <> 0 Then
        ADOo_errstring = ADOo_errstring & vbCrLf & Err.Description
        ADOp_MoveRecords = False
        If ADOo_rs(con_to).State <> 0 Then ADOo_rs(con_to).Close
        If ADOo_rs(con_from).State <> 0 Then ADOo_rs(con_from).Close
        Exit Function
    Else
        ADOp_MoveRecords = True
        Exit Function
    End If

err_active:
    If Err.Number <> 0 Then
        ADOo_errstring = ADOo_errstring & vbCrLf & Err.Description & " at field =" & ADOo_rs(con_from).Fields(i).Name & " record " & rc
        ADOp_MoveRecords = False
        ADOo_con(con_to).RollbackTrans
        ADOo_rs(con_to).Close
        ADOo_rs(con_from).Close
    Else
        ADOp_MoveRecords = True
    End If
        
End Function

Public Function ADOp_SelectS(ByRef con As Integer, ByVal sql As String, ByVal trim As Boolean, Optional ApproxSixe As Long, Optional InclHeaders As Boolean, Optional ByVal value As ADOinterface, Optional ConnectTo As String, Optional IntgrtdSec As Boolean, Optional UserName As String, Optional Password As String, Optional textconfigs As String) As String()
    
    On Error GoTo errflag
    
    Dim rs As ADODB.Recordset
    Dim x() As String
    
    If ADOo_con(con) Is Nothing Then Set ADOo_con(con) = New ADODB.Connection
    
    If ADOo_con(con).State = 0 Then
        If Not Me.ADOp_OpenCon(con, value, ConnectTo, IntgrtdSec, UserName, Password, textconfigs) Then
            GoTo conerr
        End If
    End If
    
    ADOo_con(con).CommandTimeout = 3600
    Set ADOo_rs(con) = ADOo_con(con).Execute(sql)
    ADOp_SelectS = ADOp_ExtractRecordsetS(con, trim, ApproxSixe, InclHeaders)
    If ADOo_rs(con).State <> 0 Then ADOo_rs(con).Close
    Exit Function
        
conerr:
    If Me.ADOo_errstring <> "" Then
        ReDim x(0, 0)
        x(0, 0) = "Error"
        ADOp_SelectS = x
        Exit Function
    End If
            
errflag:
    
    If Err.Number <> 0 Then
        ReDim x(0, 0)
        x(0, 0) = "Error" & Err.Number & vbCrLf & Err.Description
        Me.ADOo_errstring = "Error: " & Err.Number & vbCrLf & Err.Description
        ADOp_SelectS = x
    End If
    
End Function

Private Function ADOp_ExtractRecordsetS(ByRef con As Integer, ByRef trim As Boolean, Optional ByVal Size As Long, Optional headers As Boolean) As String()
    
    Dim i As Long
    Dim j As Long
    
    On Error GoTo err_active
    
    'if no size is provided, dim to one million
    If Size = 0 Then Size = 1000000
    
    'size table
    Dim table() As String
    
    If ADOo_rs(con).Fields.Count = 0 Then
        Do Until ADOo_rs(con).Fields.Count <> 0
            Set ADOo_rs(con) = ADOo_rs(con).NextRecordset()
            If ADOo_rs(con) Is Nothing Then Exit Do
        Loop
        
        If ADOo_rs(con) Is Nothing Then
            ReDim table(0, 0)
            ADOp_ExtractRecordsetS = table
            Exit Function
        Else
            ReDim table(ADOo_rs(con).Fields.Count - 1, Size)
        End If
    Else
        ReDim table(ADOo_rs(con).Fields.Count - 1, Size)
    End If
    
    'populate headers if requested
    If headers Then
        i = 0
        While i <= UBound(table, 1)
            table(i, 0) = ADOo_rs(con).Fields(i).Name
            i = i + 1
        Wend
    End If
    
    
    'populate array
    If headers Then
        i = 1
    Else
        i = 0
    End If
    
    While ADOo_rs(con).EOF = False
        j = 0
        While j <= (UBound(table, 1))
        If IsNull(ADOo_rs(con).Fields(j)) Then
            table(j, i) = ""
        Else
            On Error Resume Next
            If trim Then
                table(j, i) = LTrim(RTrim(ADOo_rs(con).Fields(j)))
            Else
                table(j, i) = ADOo_rs(con).Fields(j)
            End If
            If Err.Number <> 0 Then table(j, i) = "Error:" & Err.Number
            On Error GoTo err_active
        End If
            j = j + 1
        Wend
        i = i + 1
        ADOo_rs(con).MoveNext
    Wend
    
    If i = 0 Then i = 1
    ReDim Preserve table(UBound(table, 1), i - 1)
    
    
err_active:
    If Err.Number <> 0 Then
        ADOo_errstring = ADOo_errstring & vbCrLf & Err.Description & " at field =" & ADOo_rs(con).Fields(j).Name & " record " & i
        ReDim table(0, 0)
        table(0, 0) = ADOo_errstring
        ADOp_ExtractRecordsetS = table
        ADOo_rs(con).Close
    Else
        ADOp_ExtractRecordsetS = table
    End If
        
End Function



Public Function TBLp_JoinTbls(ByRef tbl1() As String, ByRef tbl2() As String, ByRef headers As Boolean, ByRef NeedsSort As Boolean, ByRef dupfactor As Integer, ParamArray flds()) As String()
    
    
    On Error GoTo errpath
    '3 arrays
    'the first 2 arrays are the joining fields
    'the next array is what fields to attach to table1
    Dim t() As String
    Dim i As Long
    Dim j As Long
    Dim k As Long
    Dim copyrow As Long
    Dim toprow As Long
    Dim found As Boolean
    Dim ntbl() As String
    Dim hr As Integer
    Dim ntrow As Long
    
    hr = 0
    If headers Then hr = 1
    
    ReDim ntbl(UBound(tbl1, 1) + UBound(flds(2)) + 1, UBound(tbl1, 2) * dupfactor)
    
    
    t = Me.PAp_2DGetStringArray(0, flds)
    For i = 0 To UBound(t)
        t(i) = "S"
    Next i
    
    If NeedsSort Then Call Me.TBLp_KeyBubbleSortAsc(tbl2, Me.PAp_2DGetIntegerArray(1, flds), True)
    
    For i = 0 To UBound(tbl1, 2)
        'If i = 6516 Then MsgBox ("x")
        For j = 0 To UBound(t)
            t(j) = tbl1(flds(0)(j), i)
        Next j
        copyrow = Me.ROWe_FindOnSorted(tbl2, toprow, found, Me.PAp_2DGetIntegerArray(1, flds), t)
        'copy both sets of rows to new table
        If found Then
            For k = copyrow To toprow
                Call ROWp_TableJoinCopy2ToNew(tbl1, tbl2, ntbl, Me.PAp_2DGetIntegerArray(2, flds), i, k, ntrow)
            Next k
        Else
            Call ROWp_TableJoinCopy1ToNew(tbl1, ntbl, i, ntrow)
        End If
    Next i
    
    'copy headers
    If headers Then
        Call ROWp_TableJoinCopy2ToNew(tbl1, tbl2, ntbl, Me.PAp_2DGetIntegerArray(2, flds), 0, 0, 0)
    End If
    
    ReDim Preserve ntbl(UBound(ntbl, 1), ntrow - 1)
    
errpath:
    If Err.Number <> 0 Then
        ADOo_errstring = ADOo_errstring & "Error in TLBp_JoinTbls" & vbCrLf & Err.Description & vbCrLf
        ReDim ntbl(0, 0)
        ntbl(0, 0) = ADOo_errstring
    End If
    TBLp_JoinTbls = ntbl

End Function

Private Sub ROWp_TableJoinCopy2ToNew(ByRef tbl1() As String, ByRef tbl2() As String, ByRef ntbl() As String, ByRef tbl2flds() As Integer, ByRef tbl1row As Long, ByRef tbl2row As Long, ByRef newrow As Long)

    Dim i As Integer
    Dim j As Integer
        
    For i = 0 To UBound(tbl1, 1)
        ntbl(i, newrow) = tbl1(i, tbl1row)
    Next i
    
    For i = 0 To UBound(tbl2flds)
        ntbl(UBound(tbl1, 1) + 1 + i, newrow) = tbl2(tbl2flds(i), tbl2row)
    Next i
    
    newrow = newrow + 1
    
End Sub

Private Sub ROWp_TableJoinCopy1ToNew(ByRef tbl1() As String, ByRef ntbl() As String, ByRef tbl1row As Long, ByRef newrow As Long)

    Dim i As Integer
    
    For i = 0 To UBound(tbl1, 1)
        ntbl(i, newrow) = tbl1(i, tbl1row)
    Next i
    
    newrow = newrow + 1
    
    
End Sub





Function PAp_2DGetStringArray(ByRef index As Integer, ParamArray pa()) As String()

    Dim str() As String
    Dim i As Long
    ReDim str(UBound(pa(0)(index)))
    
    For i = 0 To UBound(pa(0)(index))
        str(i) = pa(0)(index)(i)
    Next i
    PAp_2DGetStringArray = str
    

End Function

Function PAp_3DGetStringArray(ByRef index As Integer, ParamArray pa()) As String()


On Error GoTo errh
    'when the parameter array gets passed into this functon as another paramtere array, an unnecessary dimension has been added
    Dim str() As String
    Dim i As Long
    Dim j As Long
    ReDim str(UBound(pa(0)(index), 1), UBound(pa(0)(index), 2))
    
    For i = 0 To UBound(str, 2)
        For j = 0 To UBound(str, 1)
            str(j, i) = pa(0)(index)(j, i)
        Next j
    Next i
    
    
errh:
    If Err.Number <> 0 Then
        ADOo_errstring = ADOo_errstring & "Error at PAp_3DGetStringArray" & vbCrLf & Err.Description & vbCrLf
        ReDim str(0, 0)
        str(0, 0) = ADOo_errstring
    End If
    
    PAp_3DGetStringArray = str

End Function

Function PAp_2DGetVariantArray(ByRef index As Integer, ParamArray pa()) As Variant()

    Dim str() As Variant
    Dim i As Long
    ReDim str(UBound(pa(0)(index)))
    
    For i = 0 To UBound(pa(0)(index))
        str(i) = pa(0)(index)(i)
    Next i
    PA_2DGetVariantArray = str
    

End Function

Function PAp_2DGetLongArray(ByRef index As Integer, ParamArray pa()) As Long()

    Dim str() As Long
    Dim i As Long
    ReDim str(UBound(pa(0)(index)))
    
    For i = 0 To UBound(pa(0)(index))
        str(i) = pa(0)(index)(i)
    Next i
    PA_2DGetLongArray = str
    

End Function

Function PAp_2DGetIntegerArray(ByRef index As Integer, ParamArray pa()) As Integer()

    Dim str() As Integer
    Dim i As Long
    If UBound(pa(0)(index)) <> -1 Then
        ReDim str(UBound(pa(0)(index)))
        
        For i = 0 To UBound(pa(0)(index))
            str(i) = pa(0)(index)(i)
        Next i
    End If
    PAp_2DGetIntegerArray = str
    

End Function

Function PAp_2DGetMultIntegerArray(ByRef ArraysGet() As Integer, ParamArray pa()) As Integer()

    Dim str() As Integer
    Dim i As Long
    Dim j As Long
    Dim cnt As Long
    Dim index As Long
    

    'get length of selected arrays
    For i = 0 To UBound(ArraysGet, 1)
        cnt = cnt + UBound(pa(0)(ArraysGet(i)))
    Next i
    
    ReDim str(cnt + 1)
    cnt = 0
    
    For i = 0 To UBound(ArraysGet, 1)
        For j = 0 To UBound(pa(0)(ArraysGet(i)))
            str(cnt) = pa(0)(ArraysGet(i))(j)
            cnt = cnt + 1
        Next j
    Next i
    
    PAp_2DGetMultIntegerArray = str
    

End Function

Public Function ARRAYp_MakeInteger(ParamArray items()) As Integer()
    
    Dim x() As Integer
    Dim i As Integer
    ReDim x(UBound(items))
    
    For i = 0 To UBound(items())
        x(i) = items(i)
    Next i
    
    ARRAYp_MakeInteger = x

End Function

Public Function ARRAYp_MakeString(ParamArray items()) As String()
    
    Dim x() As String
    Dim i As Integer
    ReDim x(UBound(items))
    
    For i = 0 To UBound(items())
        x(i) = items(i)
    Next i
    
    ARRAYp_MakeString = x

End Function



Public Function MISCe_CompareString(ByRef base As String, ByRef compare As String) As Integer

    If compare < base Then
        MISCe_CompareString = -1
        Exit Function
    End If
    
    If compare = base Then
        MISCe_CompareString = 0
        Exit Function
    End If
    
    If compare > base Then
        MISCe_CompareString = 1
        Exit Function
    End If

End Function

Public Function MISCe_CompareDouble(ByRef base As Double, ByRef compare As Double) As Integer

    If compare < base Then
        MISCe_CompareDouble = -1
        Exit Function
    End If
    
    If compare = base Then
        MISCe_CompareDouble = 0
        Exit Function
    End If
    
    If compare > base Then
        MISCe_CompareDouble = 1
        Exit Function
    End If

End Function

Public Function MISCe_CompareDate(ByRef base As Date, ByRef compare As Date) As Integer

    
    If compare < base Then
        MISCe_CompareDate = -1
        Exit Function
    End If
    
    If compare = base Then
        MISCe_CompareDate = 0
        Exit Function
    End If
    
    If compare > base Then
        MISCe_CompareDate = 1
        Exit Function
    End If

End Function

Public Function ROWe_FindOnSorted(ByRef tbl() As String, ByRef range As Long, ByRef match As Boolean, ParamArray fldsvals()) As Long
    
    On Error GoTo errpath
    'has to be a lexicographically sorted table otherwise this evaluaiton will not be the same as the sort evaluaiton
    'flds has a field number and the value to get
    'returns the low point and modifies the range parameter to reflect the high point
    Dim maxrow As Long
    Dim minrow As Long
    Dim currow As Long
    Dim curkey As String
    Dim basekey As String
    Dim i As Long
    Dim j As Long
    Dim found As Boolean
    
    
    For i = 0 To UBound(fldsvals(1))
        curkey = curkey & fldsvals(1)(i)
    Next i

    maxrow = UBound(tbl, 2)
    currow = UBound(tbl, 2) \ 2
    minrow = 0
    
    Do
        Select Case Me.MISCe_CompareString(ROWp_CreateKey(tbl, Me.PAp_2DGetIntegerArray(0, fldsvals), currow), curkey)
            Case -1
                maxrow = currow
                currow = (currow - minrow) \ 2 + minrow
                'minrow stays same
                'if the spread is 10 or less just loop through due to '\' errors
                If maxrow - minrow <= 10 Then
                    currow = minrow
                    Do Until Me.MISCe_CompareString(ROWp_CreateKey(tbl, Me.PAp_2DGetIntegerArray(0, fldsvals), currow), curkey) = 0
                        currow = currow + 1
                        If currow > maxrow Then
                            match = False
                            ROWe_FindOnSorted = 0
                            Exit Function
                        End If
                    Loop
                End If
            Case 0
                'check both directions for duplicates
                If currow < UBound(tbl, 2) Then
                    i = currow + 1
                    Do Until Me.MISCe_CompareString(ROWp_CreateKey(tbl, Me.PAp_2DGetIntegerArray(0, fldsvals), i), curkey) <> 0
                        i = i + 1
                        If i > UBound(tbl, 2) Then
                            Exit Do
                        End If
                    Loop
                    i = i - 1
                Else
                    i = currow
                End If
                
                If currow > 0 Then
                    j = currow - 1
                    Do Until Me.MISCe_CompareString(ROWp_CreateKey(tbl, Me.PAp_2DGetIntegerArray(0, fldsvals), j), curkey) <> 0
                        j = j - 1
                        If j < 0 Then
                            Exit Do
                        End If
                    Loop
                    j = j + 1
                Else
                    j = currow
                End If
                
                range = i
                ROWe_FindOnSorted = j
                match = True
                Exit Function
            Case 1
                minrow = currow
                currow = (maxrow - minrow) / 2 + minrow
                'max row stays same
                'if the spread is 10 or less just loop through due to '\' errors
                If maxrow - minrow <= 10 Then
                    currow = minrow
                    Do Until Me.MISCe_CompareString(ROWp_CreateKey(tbl, Me.PAp_2DGetIntegerArray(0, fldsvals), currow), curkey) = 0
                        currow = currow + 1
                        If currow > maxrow Then
                            match = False
                            ROWe_FindOnSorted = 0
                            Exit Function
                        End If
                    Loop
                End If
        End Select
    Loop
    
errpath:
    i = i

    
End Function

Public Function ROWp_CreateKey(ByRef tbl() As String, ByRef flds() As Integer, ByRef row As Long) As String

    Dim i As Integer
    Dim s As String
    
    For i = 0 To UBound(flds)
        s = s & tbl(flds(i), row)
    Next i
    
    ROWp_CreateKey = s

End Function

Public Function SHTp_GetAllCellsConcatenated(ByRef sh As Worksheet, ByRef maxw As Long, ByRef maxl As Long) As String

    Dim i As Long
    Dim j As Long
    Dim cs As String
    
    For i = 1 To maxl
        For j = 1 To maxw
            If j > 1 Then cs = cs & vbTab
            cs = cs & sh.Cells(i, j)
        Next j
        cs = cs & " " & vbCrLf
    Next i
    
    SHTp_GetAllCellsConcatenated = cs

End Function

Public Function MISCp_msgbox_cancel(ByRef Message As String, Optional ByRef TITLE As String = "") As Boolean
    
    Application.EnableCancelKey = xlDisabled
    MsgB.tbMSG.Text = Message
    MsgB.Caption = TITLE
    MsgB.tbMSG.ScrollBars = fmScrollBarsBoth
    MsgB.Show
    MISC_msgbox_cancel = MsgB.Cancel
    Application.EnableCancelKey = xlInterrupt

End Function

Public Function TBLp_CrossJoin(ByRef tbl1() As String, ByRef tbl2() As String, ByRef headers As Boolean) As String()

    Dim t() As String
    Dim i As Long
    Dim j As Long
    Dim k As Long
    Dim m As Long
    Dim h As Integer
    
    ReDim t(UBound(tbl1, 1) + UBound(tbl2, 1) + 1, UBound(tbl1, 2) * UBound(tbl2, 2))
    
    h = 0
    If headers Then
        j = 0
        For i = 0 To UBound(tbl1, 1)
            t(i, j) = tbl1(i, j)
        Next i
        For i = 0 To UBound(tbl2, 1)
            t(i + UBound(tbl1, 1) + 1, j) = tbl2(i, j)
        Next i
        h = 1
    End If
    
    
    m = 1
    For i = h To UBound(tbl1, 2)
        For j = h To UBound(tbl2, 2)
            For k = 0 To UBound(tbl1, 1)
                t(k, m) = tbl1(k, i)
            Next k
            For k = 0 To UBound(tbl2, 1)
                t(k + UBound(tbl1, 1) + 1, m) = tbl2(k, j)
            Next k
            m = m + 1
        Next j
    Next i
    
    TBLp_CrossJoin = t
            
End Function

Function ADOp_InsertRecordsS(ByRef Records() As String, ByRef con As Integer, ByVal TableName As String, Optional headers As Boolean) As Boolean

    Dim i As Integer
    Dim j As Integer
    
   
    If ADOo_rs(con) Is Nothing Then
        Set ADOo_rs(con) = New ADODB.Recordset
    End If
    
    If ADOo_rs(con).State = 1 Then
        ADOo_rs(con).Close
    End If
    
    Call ADOo_rs(con).Open(TableName, ADOo_con(con), adOpenDynamic, adLockPessimistic)

    ADOo_con(con).BeginTrans
    
    If headers = True Then
        i = 1
    Else
        i = 0
    End If
    
    While i <= UBound(Records, 2)
        ADOo_rs(con).AddNew
        j = 0
        While j <= UBound(Records, 1)
            If Records(j, i) <> "" Then
                ADOo_rs(con)(j) = Records(j, i)
            End If
            j = j + 1
        Wend
        i = i + 1
        ADOo_rs(con).Update
    Wend
    
    ADOo_con(con).CommitTrans
    ADOo_rs(con).Close
    
inserterror:
    If Err.Number <> 0 Then
        ADOo_con(con).RollbackTrans
        ADOo_errstring = "Error encountered while adding records- #" & Err.Number & " " & Err.Description
        ADOp_InsertRecordsS = False
    Else
        ADOp_InsertRecordsS = True
        ADOo_errstring = ""
    End If
    
noconnectionstring:

End Function

Function MISCe_IsNull(ByRef stringexp As String, replacement As String) As String

    If stringexp = "" Then
        IsNull = replacement
    Else
        IsNull = stringexp
    End If

End Function


Sub TBLp_Concatenate(ByRef ARY1() As String, ByRef ARY2() As String)

    Dim temp() As String
    ReDim temp(UBound(ARY1, 1) + 1 + UBound(ARY2, 1), UBound(ARY1, 2) + UBound(ARY2, 2))
    Dim i As Integer
    Dim j As Integer
    Dim ub1 As Integer
    Dim ub2 As Integer
    
    i = 0
    While i <= UBound(ARY1, 1)
        j = 0
        While j <= UBound(ARY1, 2)
            temp(i, j) = ARY1(i, j)
            j = j + 1
        Wend
        i = i + 1
    Wend
    ub1 = i
    ub2 = j - 1
    While i <= UBound(temp, 1)
        j = 0
        While j <= ub2
            temp(i, j) = ARY2(i - ub1, j)
            j = j + 1
        Wend
        i = i + 1
    Wend
    
    ReDim Preserve temp(UBound(temp, 1), j - 1)
    ARY1() = temp()
End Sub

Sub SHTp_HyperlinkConvert(ByRef sheet As Worksheet, ByRef column As Integer, ByRef startrow As Integer, ByRef stopflag As String)

 Dim i As Integer
 Dim sh As Worksheet
 Set sh = sheet
 i = startrow
    Do Until sh.Cells(i, column) = stopflag
        Call sh.Hyperlinks.Add(sh.range(sh.Cells(i, column).Address), sh.Cells(i, column))
        i = i + 1
    Loop

End Sub

Function FILEp_GetTXT(ByRef path As String, approxrecords) As String()
    
    Dim i As Long
    Dim t() As String
    ReDim t(0, approxrecords)
    
    Dim f As New Scripting.FileSystemObject
    Dim ts As Scripting.TextStream
    
    Set ts = f.OpenTextFile(path, ForReading, False, TristateUseDefault)
    
    i = 0
    While Not ts.AtEndOfStream
        t(0, i) = ts.ReadLine
        i = i + 1
    Wend
    ReDim Preserve t(0, i - 1)
    ts.Close

    FILEp_GetTXT = t

End Function

Public Function ADOp_Exec(ByRef con As Integer, ByVal sql As String, Optional ApproxSixe As Long, Optional InclHeaders As Boolean, Optional ByVal value As ADOinterface, Optional ConnectTo As String, Optional IntgrtdSec As Boolean, Optional UserName As String, Optional Password As String, Optional textconfigs As String) As Boolean
    
    On Error GoTo errflag
    
    
    If ADOo_con(con) Is Nothing Then Set ADOo_con(con) = New ADODB.Connection
    
    If ADOo_con(con).State = 0 Then
        If Not Me.ADOp_OpenCon(con, value, ConnectTo, IntgrtdSec, UserName, Password, textconfigs) Then
            GoTo conerr
        End If
    End If
    
    Call ADOo_con(con).Execute(sql)
    ADOp_Exec = True
    Exit Function
        
conerr:
    If Me.ADOo_errstring <> "" Then
        ADOp_Exec = False
        Exit Function
    End If
            
errflag:
    
    If Err.Number <> 0 Then
        ADOp_Exec = False
        Me.ADOo_errstring = "Error: " & Err.Number & vbCrLf & Err.Description
    End If
    
End Function

Sub ADOp_CloseCon(con As Integer)

    ADOo_con(con).Close

End Sub

Public Function TBLp_Unpivot(ByRef arr() As String, ByRef pivot_field_header, ByRef content_header As String, ParamArray keepcols_stackcols()) As String()


On Error GoTo errh

    Dim keep() As Integer
    Dim stack() As Integer
    Dim i As Long
    Dim j As Long
    Dim k As Long
    Dim r As Long

    keep = Me.PAp_2DGetIntegerArray(0, keepcols_stackcols)
    stack = Me.PAp_2DGetIntegerArray(1, keepcols_stackcols)
       

    Dim n() As String
    ReDim n(UBound(keep) + 2, UBound(arr, 2) * (UBound(stack) + 1))
    
    For i = 0 To UBound(keep)
        n(i, 0) = arr(keep(i), 0)
    Next i
    
    n(UBound(keep) + 1, 0) = pivot_field_header
    n(UBound(keep) + 2, 0) = content_header
    
    r = 1
    For i = 0 To UBound(stack) 'loop through each stack field
        For j = 1 To UBound(arr, 2) 'loop through each row in the array
            For k = 0 To UBound(keep) 'loop through each field to keep
                n(k, r) = arr(keep(k), j)
            Next k
            n(UBound(keep) + 1, r) = arr(stack(i), 0) 'arr col title
            n(UBound(keep) + 2, r) = arr(stack(i), j) 'arr row content
            r = r + 1
        Next j
    Next i
    
errh:
    If Err.Number <> 0 Then
        ADOo_errstring = ADOo_errstring & "Error in tblp_unpivot" & vbCrLf & Err.Description
        ReDim n(0, 0)
        n(0, 0) = ADOo_errstring
    End If
    
    TBLp_Unpivot = n

End Function

Function TBLp_Stack_NewAr(ParamArray ar()) As String()

On Error GoTo errh
    
    Dim ar1() As String
    Dim ar2() As String
    Dim i As Long
    Dim j As Long
    Dim k As Long
    Dim r As Long
    Dim out() As String
    Dim ac As Long 'array count
    Dim al As Long 'new arrray length
    
    'get number of array is paramter array
    ac = UBound(ar, 1) + 1
    
    'get length of each array and add total for final array redim
    For i = 0 To ac - 1
        al = al + UBound(ar(i), 2)
    Next i
    
    'setup new combination array
    ReDim Preserve out(UBound(ar(0), 1), al)
    
    'set headers
    For i = 0 To UBound(out, 1)
        out(i, 0) = ar(0)(i, 0)
    Next i
    
    'get content
    r = 1
    For k = 0 To ac - 1 'loop through each array
        For j = 1 To UBound(ar(k), 2) 'loop through each row in each array
            For i = 0 To UBound(out, 1) 'loop through each column of each row of each array
                out(i, r) = ar(k)(i, j)
            Next i
            r = r + 1
        Next j
    Next k
    
errh:
    If Err.Number <> 0 Then
        ADOo_errstring = ADOo_errstring & "Error at TBLp_Stack_NewAr" & vbCrLf & Err.Description
        ReDim out(0, 0)
        out(0, 0) = ADOo_errstring
    End If
    
    TBLp_Stack_NewAr = out
    
End Function

Sub TBLp_Stack_Overwrite(ar1() As String, ar2() As String)

On Error GoTo errh
    Dim i As Long
    Dim j As Long
    Dim r As Long
    r = UBound(ar1, 2)
    
    ReDim Preserve ar1(UBound(ar1, 1), UBound(ar1, 2) + UBound(ar2, 2))
    
    For j = 1 To UBound(ar2, 2)
        For i = 0 To UBound(ar1, 1)
            ar1(i, r) = ar2(i, j)
        Next i
        r = r + 1
    Next j


errh:
    If Err.Number <> 0 Then
        ADOo_errstring = ADOo_errstring & "Error at TBLp_Stack_Overwrite" & vbCrLf & Err.Description
        ReDim ar1(0, 0)
        ar1(0, 0) = ADOo_errstring
    End If
    

End Sub


Public Function TXTp_Pad(ByRef topad As String, ByRef left_true_right_false As Boolean, ByRef padchar As String, ByRef padlength As Integer) As String
    
    If Len(topad) >= padlength Then
        Pad = topad
        Exit Function
    End If
        

    If left_true_right_false Then
        Pad = String(padlength - Len(topad), padchar) & topad
    Else
        Pad = topad & String(padlength - Len(topad), padchar)
    End If
        
    
    
End Function

Function TXTp_ParseCSVrow(ByRef csv() As String, row As Long, col As Integer) As String()
    
    Dim i As Long
    Dim ci As Long
    Dim cc() As Long
    Dim qflag As Boolean
    Dim rtn() As String
    
    ReDim cc(1000)
    ci = 1
    cc(0) = 0
    For i = 1 To Len(csv(col, row))
        If Mid(csv(col, row), i, 1) = Chr(34) Then
            If qflag = True Then
                qflag = False
            ElseIf qflag = False Then
                qflag = True
            End If
        End If
        If Mid(csv(col, row), i, 1) = "," Then
            If Not qflag Then
                cc(ci) = i
                ci = ci + 1
            End If
        End If
    Next i
    cc(ci) = i
    
    ReDim rtn(ci - 1)
    
    For i = 0 To UBound(rtn)
        rtn(i) = Mid(csv(col, row), cc(i) + 1, cc(i + 1) - (cc(i) + 1))
        If Mid(rtn(i), 1, 1) = Chr(34) Then rtn(i) = Mid(rtn(i), 2, Len(rtn(i)) - 2)
    Next i
    
    TXTp_ParseCSVrow = rtn

End Function


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

Public Function ADOp_BuildInsertSQL(ByRef tbl() As String, Target As String, trim As Boolean, start As Long, ending As Long, ParamArray ftype()) As String

    
    Dim i As Long
    Dim j As Long
    Dim sql As String
    Dim rec As String
    
    sql = "INSERT INTO " & Target & " VALUES " & vbCrLf
    For i = start To ending
        rec = ""
        If i <> start Then sql = sql & "," & vbCrLf
        rec = rec & "("
        For j = 0 To UBound(tbl, 1)
            If j <> 0 Then rec = rec & ","
            If ftype(0)(j) <> "S" Then
                If tbl(j, i) = "" Then
                    rec = rec & "NULL"
                Else
                    rec = rec & tbl(j, i)
                End If
            Else
                If trim Then
                    rec = rec & "'" & LTrim(RTrim(tbl(j, i))) & "'"
                Else
                    rec = rec & "'" & tbl(j, i) & "'"
                End If
            End If
        Next j
        rec = rec & ")"
        sql = sql & rec
    Next i
    
    ADOp_BuildInsertSQL = sql

End Function
