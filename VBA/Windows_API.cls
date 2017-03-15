Option Explicit

Private Declare PtrSafe Function OpenClipboard Lib "user32" (ByVal hwnd As LongPtr) As Long
Private Declare PtrSafe Function CloseClipboard Lib "user32" () As Long
Private Declare PtrSafe Function GetClipboardOwner Lib "user32" () As LongPtr
Private Declare PtrSafe Function SetClipboardViewer Lib "user32" (ByVal hwnd As LongPtr) As LongPtr
Private Declare PtrSafe Function GetClipboardViewer Lib "user32" () As LongPtr
Private Declare PtrSafe Function ChangeClipboardChain Lib "user32" (ByVal hwnd As LongPtr, ByVal hWndNext As LongPtr) As Long
Private Declare PtrSafe Function SetClipboardData Lib "user32" (ByVal wFormat As Long, ByVal hMem As LongPtr) As LongPtr
Private Declare PtrSafe Function GetClipboardData Lib "user32" Alias "GetClipboardDataA" (ByVal wFormat As Long) As LongPtr
Private Declare PtrSafe Function RegisterClipboardFormat Lib "user32" Alias "RegisterClipboardFormatA" (ByVal lpString As String) As Long
Private Declare PtrSafe Function CountClipboardFormats Lib "user32" () As Long
Private Declare PtrSafe Function EnumClipboardFormats Lib "user32" (ByVal wFormat As Long) As Long
Private Declare PtrSafe Function GetClipboardFormatName Lib "user32" Alias "GetClipboardFormatNameA" _
    (ByVal wFormat As Long, _
    ByVal lpString As String, _
    ByVal nMaxCount As Long) As Long
Private Declare PtrSafe Function EmptyClipboard Lib "user32" () As Long
Private Declare PtrSafe Function IsClipboardFormatAvailable Lib "user32" (ByVal wFormat As Long) As Long
Private Declare PtrSafe Function GetPriorityClipboardFormat Lib "user32" (lpPriorityList As Long, ByVal nCount As Long) As Long
Private Declare PtrSafe Function GetOpenClipboardWindow Lib "user32" () As LongPtr
Private Declare PtrSafe Function CharToOem Lib "user32" Alias "CharToOemA" _
    (ByVal lpszSrc As String, _
     ByVal lpszDst As String) As Long
Private Declare PtrSafe Function OemToChar Lib "user32" Alias "OemToCharA" (ByVal lpszSrc As String, ByVal lpszDst As String) As Long
Private Declare PtrSafe Function CharToOemBuff Lib "user32" Alias "CharToOemBuffA" _
    (ByVal lpszSrc As String, _
    ByVal lpszDst As String, _
    ByVal cchDstLength As Long) As Long
Private Declare PtrSafe Function OemToCharBuff Lib "user32" Alias "OemToCharBuffA" _
    (ByVal lpszSrc As String, _
    ByVal lpszDst As String, _
    ByVal cchDstLength As Long) As Long
Private Declare PtrSafe Function CharUpper Lib "user32" Alias "CharUpperA" (ByVal lpsz As String) As String
Private Declare PtrSafe Function CharUpperBuff Lib "user32" Alias "CharUpperBuffA" (ByVal lpsz As String, ByVal cchLength As Long) As Long
Private Declare PtrSafe Function CharLower Lib "user32" Alias "CharLowerA" (ByVal lpsz As String) As String
Private Declare PtrSafe Function CharLowerBuff Lib "user32" Alias "CharLowerBuffA" (ByVal lpsz As String, ByVal cchLength As Long) As Long
Private Declare PtrSafe Function CharNext Lib "user32" Alias "CharNextA" (ByVal lpsz As String) As String
Private Declare PtrSafe Function CharPrev Lib "user32" Alias "CharPrevA" (ByVal lpszStart As String, ByVal lpszCurrent As String) As String
Private Declare PtrSafe Function lstrcpy Lib "kernel32" Alias "lstrcpyA" (ByVal lpString1 As Any, ByVal lpString2 As Any) As LongPtr
Private Declare PtrSafe Function GlobalAlloc Lib "kernel32" (ByVal wFlags As Long, ByVal dwBytes As LongPtr) As LongPtr
Private Declare PtrSafe Function GlobalFree Lib "kernel32" (ByVal hMem As LongPtr) As LongPtr
Private Declare PtrSafe Function GlobalHandle Lib "kernel32" (wMem As Any) As LongPtr
Private Declare PtrSafe Function GlobalLock Lib "kernel32" (ByVal hMem As LongPtr) As LongPtr
Private Declare PtrSafe Function GlobalReAlloc Lib "kernel32" (ByVal hMem As LongPtr, ByVal dwBytes As LongPtr, ByVal wFlags As Long) As LongPtr
Private Declare PtrSafe Function GlobalUnlock Lib "kernel32" (ByVal hMem As LongPtr) As Long
Private Declare PtrSafe Function WaitMessage Lib "user32" () As Long
Private Declare PtrSafe Function PeekMessage Lib "user32" Alias "PeekMessageA" _
    (ByRef lpMsg As MSG, ByVal hwnd As Long, _
     ByVal wMsgFilterMin As Long, _
     ByVal wMsgFilterMax As Long, _
     ByVal wRemoveMsg As Long) As Long
Private Declare PtrSafe Function TranslateMessage Lib "user32" _
    (ByRef lpMsg As MSG) As Long
Private Declare PtrSafe Function PostMessage Lib "user32" Alias "PostMessageA" _
    (ByVal hwnd As Long, _
     ByVal wMsg As Long, _
     ByVal wParam As Long, _
     lParam As Any) As Long
Private Declare PtrSafe Function FindWindow Lib "user32" Alias "FindWindowA" _
    (ByVal lpClassName As String, _
     ByVal lpWindowName As String) As Long



Private Type POINTAPI
    x As Long
    y As Long
End Type

Private Type MSG
    hwnd As Long
    Message As Long
    wParam As Long
    lParam As Long
    time As Long
    pt As POINTAPI
End Type

Private Const WM_KEYDOWN As Long = &H100
Private Const PM_REMOVE  As Long = &H1
Private Const WM_CHAR    As Long = &H102
Private Const GHND As Long = &H42
Private Const CF_TEXT = 1
Private Const MAXSIZE = 40096
Private bExitLoop As Boolean



Public Sub SetClipboard(sUniText As String)
    Dim iStrPtr As LongPtr
    Dim iLen As LongPtr
    Dim iLock As LongPtr
    Const GMEM_MOVEABLE As Long = &H2
    Const GMEM_ZEROINIT As Long = &H40
    Const CF_UNICODETEXT As Long = &HD
    OpenClipboard 0&
    EmptyClipboard
    iLen = LenB(sUniText) + 2&
    iStrPtr = GlobalAlloc(GMEM_MOVEABLE Or GMEM_ZEROINIT, iLen)
    iLock = GlobalLock(iStrPtr)
    lstrcpy iLock, StrPtr(sUniText)
    GlobalUnlock iStrPtr
    SetClipboardData CF_UNICODETEXT, iStrPtr
    CloseClipboard
End Sub

Public Sub ClipBoard_SetData(sUniText As String)

    
    Dim hGlobalMemory As LongPtr
    Dim lpGlobalMemory As LongPtr
    Dim hClipMemory As LongPtr
    Dim x As Long
    
    hGlobalMemory = GlobalAlloc(GHND, Len(sUniText) + 1)
    
    lpGlobalMemory = GlobalLock(hGlobalMemory)
    
    lpGlobalMemory = lstrcpy(lpGlobalMemory, sUniText)
    
    If GlobalUnlock(hGlobalMemory) <> 0 Then
        GoTo OutOfHere2
    End If
    
    If OpenClipboard(0&) = 0 Then
        Exit Sub
    End If
    
    x = EmptyClipboard()
    
    hClipMemory = SetClipboardData(CF_TEXT, hGlobalMemory)
    
OutOfHere2:
    
    If CloseClipboard() = 0 Then
        MsgBox ("ruh-roh")
    End If

End Sub

Public Function GetClipboard() As String
    Dim iStrPtr As Long
    Dim iLen As Long
    Dim iLock As Long
    Dim sUniText As String
    Const CF_UNICODETEXT As Long = 13&
    OpenClipboard 0&
    If IsClipboardFormatAvailable(CF_UNICODETEXT) Then
        iStrPtr = GetClipboardData(CF_UNICODETEXT)
        If iStrPtr Then
            iLock = GlobalLock(iStrPtr)
            iLen = GlobalSize(iStrPtr)
            sUniText = String$(iLen \ 2& - 1&, vbNullChar)
            lstrcpy StrPtr(sUniText), iLock
            GlobalUnlock iStrPtr
        End If
        GetClipboard = sUniText
    End If
    CloseClipboard
End Function


Sub TrackKeyPressInit()

    Dim msgMessage As MSG
    Dim bCancel As Boolean
    Dim iKeyCode As Integer
    Dim lXLhwnd As Long

    On Error GoTo errHandler:
        Application.EnableCancelKey = xlErrorHandler
        'initialize this boolean flag.
        bExitLoop = False
        'get the app hwnd.
        lXLhwnd = FindWindow("XLMAIN", Application.Caption)
    Do
        WaitMessage
        'check for a key press and remove it from the msg queue.
        If PeekMessage _
            (msgMessage, lXLhwnd, WM_KEYDOWN, WM_KEYDOWN, PM_REMOVE) Then
            'strore the virtual key code for later use.
            iKeyCode = msgMessage.wParam
           'translate the virtual key code into a char msg.
            TranslateMessage msgMessage
            PeekMessage msgMessage, lXLhwnd, WM_CHAR, _
            WM_CHAR, PM_REMOVE
           'for some obscure reason, the following
          'keys are not trapped inside the event handler
            'so we handle them here.
            If iKeyCode = vbKeyBack Then SendKeys "{BS}"
            If iKeyCode = vbKeyReturn Then SendKeys "{ENTER}"
           'assume the cancel argument is False.
            bCancel = False
            'the VBA RaiseEvent statement does not seem to return ByRef arguments
            'so we call a KeyPress routine rather than a propper event handler.
            Sheet_KeyPress ByVal msgMessage.wParam, ByVal iKeyCode, ByVal Selection, bCancel
            'if the key pressed is allowed post it to the application.
            If bCancel = False Then
                PostMessage _
                lXLhwnd, msgMessage.Message, msgMessage.wParam, 0
            End If
        End If
errHandler:
        'allow the processing of other msgs.
        DoEvents
    Loop Until bExitLoop

End Sub

Sub StopKeyWatch()

    'set this boolean flag to exit the above loop.
    bExitLoop = True

End Sub


'\\This example illustrates how to catch worksheet
'\\Key strokes in order to prevent entering numeric
'\\characters in the Range "A1:D10" .
Private Sub Sheet_KeyPress(ByVal KeyAscii As Integer, ByVal KeyCode As Integer, ByVal Target As range, Cancel As Boolean)

    Const MSG As String = "Numeric Characters are not allowed in" & vbNewLine & "the Range:  """
    Const TITLE As String = "Invalid Entry !"

    If Not Intersect(Target, range("A1:D10")) Is Nothing Then
        If Chr(KeyAscii) Like "[0-9]" Then
            MsgBox MSG & range("A1:D10").Address(False, False) _
            & """ .", vbCritical, TITLE
            Cancel = True
        End If
    End If

End Sub

