Attribute VB_Name = "basMacro"
'-----------------------------------------------------------------------------------------------------
'
' [RelaxTools-Addin] v4
'
' Copyright (c) 2009 Yasuhiro Watanabe
' https://github.com/RelaxTools/RelaxTools-Addin
' author:relaxtools@opensquare.net
'
' The MIT License (MIT)
'
' Permission is hereby granted, free of charge, to any person obtaining a copy
' of this software and associated documentation files (the "Software"), to deal
' in the Software without restriction, including without limitation the rights
' to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
' copies of the Software, and to permit persons to whom the Software is
' furnished to do so, subject to the following conditions:
'
' The above copyright notice and this permission notice shall be included in all
' copies or substantial portions of the Software.
'
' THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
' IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
' FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
' AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
' LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
' OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
' SOFTWARE.
'
'-----------------------------------------------------------------------------------------------------
Option Explicit
Option Private Module


'--------------------------------------------------------------
'　キー実行ラッパー
'--------------------------------------------------------------
Sub execOnKey(ByVal strMacro As String, ByVal strLabel As String)

    On Error Resume Next

    '開始ログ
    Logger.LogBegin strMacro
    
    Application.Run strMacro
    
    If CBool(GetSetting(C_TITLE, "Option", "OnRepeat", True)) Then
        Application.OnRepeat strLabel, strMacro
    End If
    
    '終了ログ
    Logger.LogFinish strMacro
    
End Sub
'--------------------------------------------------------------
'　暗号化バッファエリア
'--------------------------------------------------------------
'Private mbytBuf() As Byte

Sub saveWorkSheets()
        
    Dim b As Workbook
    Dim o As Object
    Dim vntFileName As Variant
    
    On Error GoTo ErrHandle
        
    vntFileName = Application.GetSaveAsFilename(InitialFileName:="", FileFilter:="Excel ブック(*.xlsx),*.xlsx,Excel マクロ有効ブック(*.xlsm),*.xlsm,Excel 97-2003ブック(*.xls),*.xls", Title:="ブックの保存")
    
    If vntFileName <> False Then
    
        For Each b In Workbooks
            If UCase(b.Name) = UCase(rlxGetFullpathFromFileName(vntFileName)) Then
                MsgBox "現在開いているブックと同じ名前は指定できません。", vbOKOnly + vbExclamation, C_TITLE
                Exit Sub
            End If
        Next
        
        If rlxIsFileExists(vntFileName) Then
            If MsgBox("すでに同名のブックが存在すします。上書きしますか？", vbOKCancel + vbQuestion, C_TITLE) <> vbOK Then
                Exit Sub
            End If
        End If
    
        Application.DisplayAlerts = False
        ActiveWorkbook.Windows(1).SelectedSheets.Copy
        Set b = ActiveWorkbook
        Select Case LCase(Mid$(vntFileName, InStr(vntFileName, ".") + 1))
            Case "xls"
                b.SaveAs FileName:=vntFileName, FileFormat:=xlExcel8, Local:=True
            Case "xlsm"
                b.SaveAs FileName:=vntFileName, FileFormat:=xlOpenXMLWorkbookMacroEnabled, Local:=True
            Case Else
                b.SaveAs FileName:=vntFileName, Local:=True
        End Select
        b.Close
        Set b = Nothing
        Application.DisplayAlerts = True
        MsgBox "保存しました。", vbOKOnly + vbInformation, C_TITLE
    End If
     
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE

End Sub
'--------------------------------------------------------------
'　行コピー
'--------------------------------------------------------------
Sub lineCopy()

    If ActiveCell Is Nothing Then
        Exit Sub
    End If

    Dim f As Long
    Dim t As Long
    
    f = Selection(1, 1).row
    t = f + Selection.Rows.count - 1
    
    On Error Resume Next
    Application.ScreenUpdating = False
    
    ThisWorkbook.Worksheets("Undo").Cells.Clear
    
    Set mUndo.sourceRange = Rows(f & ":" & t)
    Set mUndo.destRange = Nothing
    
    Rows(f & ":" & t).Copy
    Rows(f & ":" & t).Insert Shift:=xlDown
    Application.CutCopyMode = False
    
    Call ShiftDown
    
    Application.ScreenUpdating = True
    
    'Undo
    Application.OnUndo "行追加", "execInsUndo"
    
    
End Sub
'--------------------------------------------------------------
'　行挿入
'--------------------------------------------------------------
Sub lineInsert()
    
    If ActiveCell Is Nothing Then
        Exit Sub
    End If

    Dim f As Long
    Dim t As Long
    
    f = Selection(1, 1).row
    t = f + Selection.Rows.count - 1
    
    On Error Resume Next
    Application.ScreenUpdating = False
    
    ThisWorkbook.Worksheets("Undo").Cells.Clear
    
    Set mUndo.sourceRange = Rows(f & ":" & t)
    Set mUndo.destRange = Nothing
    
    Rows(f & ":" & t).Insert Shift:=xlUp
    Application.CutCopyMode = False
    
    Set mUndo.sourceRange = Rows(f & ":" & t)
    
   ' Call ShiftUp
    
    Application.ScreenUpdating = True
    
    'Undo
    Application.OnUndo "行追加", "execInsUndo"
    
End Sub
'--------------------------------------------------------------
'　行削除
'--------------------------------------------------------------
Sub lineDel()

    If ActiveCell Is Nothing Then
        Exit Sub
    End If

    Dim f As Long
    Dim t As Long
    
    f = Selection(1, 1).row
    t = f + Selection.Rows.count - 1
    
    On Error Resume Next
    Application.ScreenUpdating = False
    
    ThisWorkbook.Worksheets("Undo").Cells.Clear
    
    Set mUndo.sourceRange = Range(Cells(f, 1), Cells(t, Columns.count - 1))
    Set mUndo.destRange = ThisWorkbook.Worksheets("Undo").Range(mUndo.sourceRange.Address)
    
    mUndo.sourceRange.Copy mUndo.destRange
    
    Rows(f & ":" & t).Delete xlUp
    
    Set mUndo.sourceRange = Range(Cells(f, 1), Cells(t, Columns.count - 1))
    
    Application.CutCopyMode = False
    Application.ScreenUpdating = True
    
    Selection.Select
    
    'Undo
    Application.OnUndo "行削除", "execDelUndo"
    
    
End Sub
'--------------------------------------------------------------
'　複数行コピー
'--------------------------------------------------------------
Sub lineNCopy()

    Dim lngBuf As Long
    Dim lngDest As Long
    Dim lngCnt As Long
    Dim f As Long
    Dim t As Long
    
    If ActiveCell Is Nothing Then
        Exit Sub
    End If

    lngBuf = frmInputLength.Start("行をコピーする数を入力してください。" & vbCrLf & "上限(1000)")
    If lngBuf = 0 Then
        Exit Sub
    End If

    If lngBuf > 1000 Then
        Exit Sub
    End If

'    lngDest = ActiveCell.row + Val(strbuf) - 1
    lngDest = lngBuf

    f = Selection(1, 1).row
    t = f + Selection.Rows.count - 1

    On Error Resume Next
    Application.ScreenUpdating = False
    For lngCnt = 1 To lngDest
        Rows(f & ":" & t).Copy
        Rows(f & ":" & t).Insert Shift:=xlDown
    Next
    Application.CutCopyMode = False
    Application.ScreenUpdating = True
    
End Sub
'--------------------------------------------------------------
'　Rangeが取得できるかどうかチェックする
'--------------------------------------------------------------
Function rlxCheckSelectRange() As Boolean
Attribute rlxCheckSelectRange.VB_Description = "ワークシート関数として使用できません。"
Attribute rlxCheckSelectRange.VB_ProcData.VB_Invoke_Func = " \n19"
    
    On Error GoTo ErrHandle
    
    rlxCheckSelectRange = False
    
    Select Case True
        Case ActiveWorkbook Is Nothing
            Exit Function
        Case ActiveCell Is Nothing
            Exit Function
        Case Selection Is Nothing
            Exit Function
        Case TypeOf Selection Is Range
            'OK
        Case Else
            Exit Function
    End Select

    rlxCheckSelectRange = True

    Exit Function
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE

End Function
'--------------------------------------------------------------
'　クリップボード貼り付け
'--------------------------------------------------------------
Public Sub putClipboard(ByVal strBuf As String)
    On Error GoTo ErrHandle


    SetClipText strBuf
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE

End Sub
'--------------------------------------------------------------
'　使用されているエリアの選択
'--------------------------------------------------------------
Sub usedRangeSelect()
    On Error GoTo ErrHandle
    If ActiveCell Is Nothing Then
        Exit Sub
    End If
    
    ActiveSheet.UsedRange.Select
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE

End Sub
'--------------------------------------------------------------
'　カーソルのあるエリアの選択
'--------------------------------------------------------------
Sub currentRegionSelect()
    On Error GoTo ErrHandle

    If ActiveCell Is Nothing Then
        Exit Sub
    End If
    
    ActiveCell.CurrentRegion.Select

    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE

End Sub
'--------------------------------------------------------------
'　メニュー設置値出力（デバッグ機能）
'--------------------------------------------------------------
Sub commandList()

    Dim c As CommandBar
    Dim D As CommandBarControl
    
    Dim lngCnt As Long
    
    On Error GoTo ErrHandle
    
    If ActiveCell Is Nothing Then
        Exit Sub
    End If
    
    If MsgBox("現在のシートにメニュー設定値を出力します。よろしいですか？", vbQuestion + vbOKCancel, C_TITLE) <> vbOK Then
        Exit Sub
    End If
    
    lngCnt = 1

    For Each c In CommandBars

        For Each D In c.Controls

            Cells(lngCnt, 1) = c.Name
            Cells(lngCnt, 2) = c.NameLocal
        
            Cells(lngCnt, 3) = D.Caption
            Cells(lngCnt, 4) = D.id
            
            lngCnt = lngCnt + 1
        Next
    Next
    Exit Sub
ErrHandle:
    MsgBox "エラー"
End Sub
'--------------------------------------------------------------
'　名前を全削除
'--------------------------------------------------------------
Sub delnamae()

    On Error GoTo ErrHandle
    
    '変数宣言
    Dim namae As Name '名前
    Dim namae_del As String '消滅した名前リスト
    
    If ActiveWorkbook Is Nothing Then
        MsgBox "アクティブなブックが見つかりません。", vbCritical, C_TITLE
        Exit Sub
    End If
    
    If MsgBox("ブック内の全ての名前を削除します(「Print_」で始まるもの以外)。よろしいですか？", vbQuestion + vbOKCancel, C_TITLE) <> vbOK Then
        Exit Sub
    End If
        namae_del = ""
    
    '名前消滅
    For Each namae In ActiveWorkbook.Names
        If InStr(namae.Name, "Print_") > 0 Then
        Else
            namae_del = namae_del & vbCrLf & namae.Name
            namae.Delete
        End If
    Next
    
    '結果報告
    If Len(namae_del) = 0 Then
        MsgBox "名前がありませんでした。", vbExclamation, C_TITLE
    Else
        MsgBox "以下の名前を消滅させました。" & namae_del, vbInformation, C_TITLE
    End If

    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE

End Sub
'--------------------------------------------------------------
'　すべてのシートの選択位置をＡ１にセット
'--------------------------------------------------------------
Sub setAllA1()

    On Error Resume Next
    Dim WS As Worksheet
    Dim WD As Window
    Dim sw As Boolean
    Dim Wb As Workbook
    Dim blnRatio As Boolean
    Dim lngPercent As Long
 
    If ActiveWorkbook Is Nothing Then
        MsgBox "アクティブなブックが見つかりません。", vbCritical, C_TITLE
        Exit Sub
    End If
    
    blnRatio = GetSetting(C_TITLE, "A1Setting", "ratio", False)
    lngPercent = Val(GetSetting(C_TITLE, "A1Setting", "percent", "100"))
    If lngPercent = 0 Then
        lngPercent = 100
    End If
    
    sw = False
    If Application.ScreenUpdating Then
        sw = True
    End If
    
    If sw Then
        Application.ScreenUpdating = False
    End If
  
    Set Wb = ActiveWorkbook
  
    For Each WS In Wb.Worksheets
        If WS.visible = xlSheetVisible Then
            WS.Activate
            WS.Range("A1").Activate
            Wb.Windows(1).ScrollRow = 1
            Wb.Windows(1).ScrollColumn = 1
            If blnRatio Then
                Wb.Windows(1).Zoom = lngPercent
            End If
        End If
    Next

    '非表示の１枚目を選択して「はぁ？」状態だったので表示中の１枚目にする。
    'ActiveWorkbook.Worksheets(1).Select
    For Each WS In Wb.Worksheets
        If WS.visible = xlSheetVisible Then
            WS.Select
            Exit For
        End If
    Next
    
    Set Wb = Nothing
    
    If sw Then
        Application.ScreenUpdating = True
    End If
    
End Sub

'--------------------------------------------------------------
'　すべてのシートの選択位置をＡ１にセットして保存
'--------------------------------------------------------------
Sub setAllA1save()

    Dim fname As String
    Dim varRet As Variant

    If ActiveWorkbook Is Nothing Then
        MsgBox "アクティブなブックが見つかりません。", vbCritical, C_TITLE
        Exit Sub
    End If

    Application.ScreenUpdating = False
    
    Call setAllA1
    
    On Error Resume Next
    
    mA1Save = True
    
    If ActiveWorkbook.ReadOnly Then
        MsgBox "読み取り専用ブックのため保存できません。", vbOKOnly + vbCritical, C_TITLE
        GoTo pass
    End If
    
    If rlxIsFileExists(ActiveWorkbook.FullName) Then
    Else
        MsgBox "まだ一度も保存していないファイルです。一度Excelで保存を行ってください。", vbOKOnly + vbExclamation, C_TITLE
        GoTo pass
    End If
    
    varRet = getAttr(ActiveWorkbook.FullName)
    If err.Number > 0 Then
        MsgBox "現在のファイルにアクセスできませんでした。保存できませんでした。", vbOKOnly + vbExclamation, C_TITLE
        GoTo pass
    End If
    
    If (varRet And vbReadOnly) > 0 Then
        MsgBox "指定されたファイルは読み取り専用です。保存できませんでした。", vbOKOnly + vbExclamation, C_TITLE
        GoTo pass
    End If
    
    
    ActiveWorkbook.Save

    
pass:
    mA1Save = False
    
    Application.ScreenUpdating = True

End Sub
'--------------------------------------------------------------
'　シート名をクリップボードに貼り付け
'--------------------------------------------------------------
Sub getSheetName()

    Dim WS As Object
    Dim strBuf As String
  
    On Error GoTo ErrHandle
  
    If ActiveWorkbook Is Nothing Then
        MsgBox "アクティブなブックが見つかりません。", vbCritical, C_TITLE
        Exit Sub
    End If
  
    strBuf = ""
    For Each WS In Sheets
            
        strBuf = strBuf & WS.Name & vbCrLf

    Next

    'クリップボード貼り付け
    putClipboard strBuf
    
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE

End Sub

'-----------------------------------------------------------------------
'　開いているワークブック名（ブック名のみ）をクリップボードに貼り付け
'------------------------------------------------------------------------
Sub getBookName()

    Dim Wb As Workbook
    Dim strBuf As String
    
    On Error GoTo ErrHandle
  
    If ActiveWorkbook Is Nothing Then
        MsgBox "アクティブなブックが見つかりません。", vbCritical, C_TITLE
        Exit Sub
    End If
    
    strBuf = ""
    For Each Wb In Workbooks
        strBuf = strBuf & Wb.Name & vbCrLf
    Next
    
    'クリップボード貼り付け
    putClipboard strBuf
    
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE
    
End Sub

'------------------------------------------------------------------
'　開いているワークブック名（フルパス）をクリップボードに貼り付け
'------------------------------------------------------------------
Sub getBookFullName()

    Dim Wb As Workbook
    Dim strBuf As String
    
    On Error GoTo ErrHandle
  
    If ActiveWorkbook Is Nothing Then
        MsgBox "アクティブなブックが見つかりません。", vbCritical, C_TITLE
        Exit Sub
    End If
    
    strBuf = ""
    For Each Wb In Workbooks
        strBuf = strBuf & rlxDriveToUNC(Wb.FullName) & vbCrLf
    Next
    
    'クリップボード貼り付け
    putClipboard strBuf
    
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE
    
End Sub

'--------------------------------------------------------------
'　現在のワークブック名（フルパス）をクリップボードに貼り付け
'--------------------------------------------------------------
Sub getCurrentBookFullName()
    
    On Error GoTo ErrHandle

    If ActiveWorkbook Is Nothing Then
        MsgBox "アクティブなブックが見つかりません。", vbCritical, C_TITLE
        Exit Sub
    End If
    
    'クリップボード貼り付け
    putClipboard rlxDriveToUNC(ActiveWorkbook.FullName) '& vbCrLf
    
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE
    
End Sub
'--------------------------------------------------------------
'　現在のワークブック名（フルパス）をクリップボードに貼り付け
'--------------------------------------------------------------
Sub getCurrentBookName()

    On Error GoTo ErrHandle
    
    If ActiveWorkbook Is Nothing Then
        MsgBox "アクティブなブックが見つかりません。", vbCritical, C_TITLE
        Exit Sub
    End If
    
    'クリップボード貼り付け
    putClipboard rlxDriveToUNC(ActiveWorkbook.Name) '& vbCrLf
    
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE
    
End Sub

'--------------------------------------------------------------
'　現在のワークブック名（フルパス）のフォルダを開く
'--------------------------------------------------------------
Sub openDocumentPath()
    
    Dim WSH As Object
    Dim wExec As Object
    
    On Error Resume Next

    If ActiveWorkbook Is Nothing Then
        MsgBox "アクティブなブックが見つかりません。", vbCritical, C_TITLE
        Exit Sub
    End If
    
   
    Set WSH = CreateObject("WScript.Shell")
    
    WSH.Run ("""" & rlxGetFullpathFromPathName(rlxDriveToUNC(ActiveWorkbook.FullName)) & """")
    
    Set wExec = Nothing
    Set WSH = Nothing
    
End Sub
'--------------------------------------------------------------
'　ワークブックの分割
'--------------------------------------------------------------
Sub divideWorkBook()

    Dim strWorkPath As String
    Dim WS As Worksheet
    Dim W2 As Worksheet
    Dim motoWB As Workbook
    Dim Wb As Workbook
    Dim WSH As Object
    
    On Error GoTo ErrHandle
    
    If ActiveWorkbook Is Nothing Then
        MsgBox "アクティブなブックが見つかりません。", vbCritical, C_TITLE
        Exit Sub
    End If
    
    If MsgBox("現在のブックの作業フォルダに「ブック名_シート名」でシート毎に分割します。" & vbCrLf & "よろしいですか？(非表示シートは処理しません)", vbOKCancel + vbQuestion, C_TITLE) <> vbOK Then
        Exit Sub
    End If
    
    '現在のワークブックを対象とする。
    Set motoWB = ActiveWorkbook
    
    If motoWB Is Nothing Then
        Exit Sub
    End If
    
    strWorkPath = motoWB.Path
    If strWorkPath = "" Then
        MsgBox "元ブックのパスが取得できません。保存してから再度実行してください。", vbExclamation, C_TITLE
        Exit Sub
    End If

    For Each WS In motoWB.Worksheets
    
        If WS.visible = xlSheetVisible Then

            '現在のシートをコピーして新規のワークブックを作成する。
            WS.Copy
            
            Set Wb = ActiveWorkbook
            
            '新規作成したワークブックを保存する。フォーマットは親と同じ
            Application.DisplayAlerts = False
            Wb.SaveAs FileName:=rlxAddFileSeparator(strWorkPath) & rlxGetFullpathFromExt(motoWB.Name) & "_" & WS.Name, FileFormat:=motoWB.FileFormat, Local:=True
            Application.DisplayAlerts = True
            Wb.Close
    
            Set Wb = Nothing
            
        End If
    Next

    '分割したフォルダを開く
    On Error Resume Next

    Set WSH = CreateObject("WScript.Shell")
    
    WSH.Run ("""" & rlxGetFullpathFromPathName(rlxDriveToUNC(motoWB.FullName)) & """")
    
    Set WSH = Nothing
    
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE
    
End Sub
'--------------------------------------------------------------
'　ワークブックのマージ
'--------------------------------------------------------------
Sub mergeWorkBook()

    Dim strWorkPath As String
    Dim WS As Worksheet
    Dim W2 As Worksheet
    Dim motoWB As Workbook
    Dim Wb As Workbook
    
    Dim blnFirst As Boolean
    
    On Error GoTo ErrHandle
    
    
    'ワークブックが２未満の場合、処理不要
    If Workbooks.count < 2 Then
        Exit Sub
    End If
    
    blnFirst = True
    
    For Each Wb In Workbooks

        For Each WS In Wb.Worksheets
            If blnFirst Then
                WS.Copy
                Set motoWB = ActiveWorkbook
                blnFirst = False
            Else
                WS.Copy , motoWB.Worksheets(motoWB.Worksheets.count)
            End If
        Next
        
    Next
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE

End Sub

'--------------------------------------------------------------
'　選択範囲の画像変換
'--------------------------------------------------------------
Sub execSelectionPictureCopy()

    Dim blnFillVisible As Boolean
    Dim lngFillColor As Long
    Dim blnLine As Boolean
    Dim blnB As Boolean

    Call getCopyScreenSetting(blnFillVisible, lngFillColor, blnLine)
    
    blnB = ActiveWindow.DisplayGridlines
    ActiveWindow.DisplayGridlines = blnLine

    On Error GoTo ErrHandle

    If ActiveCell Is Nothing Then
        Exit Sub
    End If
    
    Selection.CopyPicture Appearance:=xlScreen, Format:=xlPicture
    ActiveSheet.Paste
    
    ActiveWindow.DisplayGridlines = blnB
    
    Selection.ShapeRange.Fill.ForeColor.RGB = lngFillColor
    
    If blnFillVisible Then
        Selection.ShapeRange.Fill.visible = msoFalse
    Else
        Selection.ShapeRange.Fill.visible = msoTrue
    End If
    
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE

End Sub
'--------------------------------------------------------------
'　ファイルの難読化
'　バッファ読み込み対応(2GB以下)
'--------------------------------------------------------------
Sub encryptionFileEx()

    Dim strFile As String
    Dim intIn As Integer
    Dim intOut As Integer
    Dim lngSize As Long
    Dim i As Long
    Dim bytBuf() As Byte
    
    Dim lngRead As Long
    
    Const KEY As Byte = &H44
    Const C_BUFFER_SIZE = 10485760 '10MB
    Const C_TEMP_FILE_EXT As String = ".tmp"
    
    On Error GoTo ErrHandle
    
    strFile = Application.GetOpenFilename(, , "ファイルの難読化", , False)
    If strFile = "False" Then
        'ファイル名が指定されなかった場合
        Exit Sub
    End If
    
    'ファイルの存在チェック
    If rlxIsFileExists(strFile) Then
    Else
        MsgBox "ファイルが存在しません。", vbExclamation, C_TITLE
        Exit Sub
    End If

    intIn = FreeFile()
    Open strFile For Binary As intIn
    
    intOut = FreeFile()
    Open strFile & C_TEMP_FILE_EXT For Binary As intOut
    
    lngSize = LOF(intIn)
    
    Do While lngSize > 0
    
        If lngSize < C_BUFFER_SIZE Then
            lngRead = lngSize
        Else
            lngRead = C_BUFFER_SIZE
        End If
    
        '最大で10MBのメモリを確保。
        ReDim bytBuf(0 To lngRead - 1)
    
        '確保したバイト数分読み込み
        Get intIn, , bytBuf
        
        'なんちゃって暗号化
        For i = 0 To lngRead - 1
            bytBuf(i) = bytBuf(i) Xor KEY
        Next
        
        '結果を書き込む
        Put intOut, , bytBuf

        lngSize = lngSize - lngRead
    Loop

    Close intIn
    Close intOut
    
    Kill strFile
    Name strFile & C_TEMP_FILE_EXT As strFile

    MsgBox "難読化／復号化が完了しました。", vbInformation, C_TITLE
    
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE


End Sub
'--------------------------------------------------------------
'　クリップボードにあるＣＳＶデータを
'　現在のシートに文字列として貼り付けます。
'--------------------------------------------------------------
Sub pasteCSV()

    Dim CB As New DataObject
    Dim strBuf As String
    Dim varRow As Variant
    Const STANDARD_DATA As Long = 1
    
    On Error GoTo ErrHandle
    
    If ActiveCell Is Nothing Then
        Exit Sub
    End If
    
    With CB
        .GetFromClipboard
        If .GetFormat(STANDARD_DATA) = False Then
            Exit Sub
        End If
        
        strBuf = .getText
        
    End With
    
    'CRLFを区切りとして行単位に分割
    Dim strCsv() As String
    Select Case True
        Case InStr(strBuf, vbCrLf) > 0
            strCsv = Split(strBuf, vbCrLf)
        Case InStr(strBuf, vbLf) > 0
            strCsv = Split(strBuf, vbLf)
        Case Else
            strCsv = Split(strBuf, vbCr)
    End Select

    Dim lngCount As Long
    lngCount = UBound(strCsv) + 1
    If lngCount < 1 Then
        Exit Sub
    End If
    
    Dim i As Long
    Dim col As Collection
    Dim lngCol As Long
    Dim lngRow As Long
    Dim r As Range
    
    lngRow = ActiveCell.row
    For i = 0 To lngCount - 1
    
        'カンマ区切りで分割を行う（ダブルコーテーション内カンマ対応）
        varRow = rlxCsvPart(strCsv(i))
        
        lngCol = ActiveCell.Column
        
        '最初の１回目
        If i = 0 Then
            '項目数の分、列の選択をし、文字列形式にする。
            Set r = Range(Columns(lngCol), Columns(lngCol + UBound(varRow) - 1))
            r.NumberFormatLocal = "@"
        End If
        
        '行単位に貼り付け
        Range(Cells(lngRow, lngCol), Cells(lngRow, lngCol + UBound(varRow) - 1)).value = varRow
    
        lngRow = lngRow + 1
    Next

    'すべて貼り付けたら列間隔を調整
    If r Is Nothing Then
    Else
        r.AutoFit
        Set r = Nothing
    End If
    
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE


End Sub
'--------------------------------------------------------------
'　文字列の分割（カンマ）
'--------------------------------------------------------------
Public Function rlxCsvPart(ByVal strBuf As String) As Variant
Attribute rlxCsvPart.VB_Description = "ワークシート関数として使用できません。"
Attribute rlxCsvPart.VB_ProcData.VB_Invoke_Func = " \n19"

    Dim lngLen As Long
    Dim lngCnt As Long
    Dim i As Long
    Dim strCol As String
    
    Dim blnSw As Boolean
    
    Const C_QUAT As String = """"
    Const C_COMA As String = ","
    
    Dim result() As Variant
    
    On Error GoTo ErrHandle
    
    lngLen = Len(strBuf)
    blnSw = False
    strCol = ""
    lngCnt = 0
    
    For i = 1 To lngLen
    
        Dim strChar As String
        strChar = Mid$(strBuf, i, 1)
        
        Select Case strChar
            Case C_QUAT
                If blnSw Then
                    blnSw = False
                Else
                    blnSw = True
                End If
            Case C_COMA
                If blnSw Then
                    strCol = strCol & strChar
                Else
                    lngCnt = lngCnt + 1
                    ReDim Preserve result(1 To lngCnt)
                    result(lngCnt) = strCol
                    strCol = ""
                End If
            Case Else
                strCol = strCol & strChar
        End Select

    Next
    
    lngCnt = lngCnt + 1
    ReDim Preserve result(1 To lngCnt)
    result(lngCnt) = strCol

    rlxCsvPart = result
    
    Exit Function
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE
End Function
'--------------------------------------------------------------
'　共有ブックのユーザ名取得
'--------------------------------------------------------------
Sub getShareUsers()

    Dim Users As Variant
    Dim strBuf As String
    Dim i As Long
    
    On Error GoTo er
    
    If ActiveWorkbook Is Nothing Then
        MsgBox "アクティブなブックが見つかりません。", vbCritical, C_TITLE
        Exit Sub
    End If
    
    Users = ActiveWorkbook.UserStatus
    
    strBuf = "現在このBookを編集しているユーザ：" & vbCrLf & vbCrLf
    For i = LBound(Users) To UBound(Users)
        strBuf = strBuf & rlxAscLeft(Users(i, 1) & Space(16), 16) & vbTab & Format(Users(i, 2), "yyyy/mm/dd hh:nn:ss") & vbTab
        Select Case Users(i, 3)
            Case 1
                strBuf = strBuf & "排他"
            Case 2
                strBuf = strBuf & "共有"
        End Select
        strBuf = strBuf & vbCrLf
        
    Next i
    
    MsgBox strBuf, vbInformation, C_TITLE

    Exit Sub
er:
    MsgBox "現在のブックは排他使用です。", vbExclamation, C_TITLE

End Sub

'--------------------------------------------------------------
'　単票データ取込シート呼出(&T)
'--------------------------------------------------------------
Sub callTanpyo()
    On Error GoTo ErrHandle

    ThisWorkbook.Worksheets("単票形式ファイル読込定義シート").Copy
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE
End Sub
'--------------------------------------------------------------
'　ヘルプシート呼出(&T)
'--------------------------------------------------------------
Sub callHelp()
    On Error GoTo ErrHandle

    ThisWorkbook.Worksheets("HELP").Copy
    
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE
End Sub
'--------------------------------------------------------------
'　選択範囲の左シフト
'--------------------------------------------------------------
Sub ShiftLeft()
    On Error GoTo ErrHandle
    If ActiveCell Is Nothing Then
        Exit Sub
    End If
    SelectionShiftCell 0, -1
    
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE
End Sub
'--------------------------------------------------------------
'　選択範囲の右シフト
'--------------------------------------------------------------
Sub ShiftRight()
    On Error GoTo ErrHandle
    If ActiveCell Is Nothing Then
        Exit Sub
    End If
    SelectionShiftCell 0, 1
    
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE
End Sub
'--------------------------------------------------------------
'　選択範囲の上シフト
'--------------------------------------------------------------
Sub ShiftUp()
    On Error GoTo ErrHandle
    If ActiveCell Is Nothing Then
        Exit Sub
    End If
    SelectionShiftCell -1, 0
    
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE
End Sub
'--------------------------------------------------------------
'　選択範囲の下シフト
'--------------------------------------------------------------
Sub ShiftDown()

    On Error GoTo ErrHandle
    
    If ActiveCell Is Nothing Then
        Exit Sub
    End If
    SelectionShiftCell 1, 0
    
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE
End Sub
'--------------------------------------------------------------
'　選択範囲シフト
'--------------------------------------------------------------
Private Sub SelectionShiftCell(ByVal lngRow As Long, ByVal lngCol As Long)
    
    Dim r As Range
    Dim c As Range
    
    On Error GoTo ErrHandle
    
    If ActiveCell Is Nothing Then
        Exit Sub
    End If
    
    For Each r In Selection.Areas
    
        err.Clear
        On Error Resume Next
        If c Is Nothing Then
            Set c = r.Offset(lngRow, lngCol)
        Else
            Set c = Union(c, r.Offset(lngRow, lngCol))
        End If
    
    Next

    If c Is Nothing Then
    Else
        c.Select
    End If

    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE

End Sub
'--------------------------------------------------------------
'　参照用ワークブック表示
'--------------------------------------------------------------
Public Sub createReferenceBook()

    Dim strActBook As String
    Dim strTmpBook As String

    Dim FS As Object
    Dim Wb As Workbook
    Dim XL As Excel.Application

    On Error GoTo ErrHandle
    
    If ActiveWorkbook Is Nothing Then
        Exit Sub
    End If
    
    
    If ActiveWorkbook.Path = "" Then
        MsgBox "元ブックのパスが取得できません。保存してから再度実行してください。", vbExclamation, C_TITLE
        Exit Sub
    End If

    Dim blnResult As Boolean
    If frmReference.Start(blnResult) = vbCancel Then
        Exit Sub
    End If


    Set FS = CreateObject("Scripting.FileSystemObject")

    strActBook = ActiveWorkbook.FullName
    strTmpBook = rlxGetTempFolder() & C_REF_TEXT & FS.getFileName(ActiveWorkbook.Name)

    FS.CopyFile strActBook, strTmpBook

    If blnResult Then
        Set XL = New Excel.Application
        
        XL.visible = True
        
        Set Wb = XL.Workbooks.Open(FileName:=strTmpBook, ReadOnly:=True)
        AppActivate XL.Caption
    Else
        Set Wb = Workbooks.Open(FileName:=strTmpBook, ReadOnly:=True)
        AppActivate Application.Caption
    
    End If
    
    Set FS = Nothing

    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE
End Sub
'--------------------------------------------------------------
'　現在のブックを読み取り専用で開きなおす
'--------------------------------------------------------------
Public Sub changeReferenceBook()

    Dim strActBook As String
    Dim strTmpBook As String

    Dim FS As Object
    Dim Wb As Workbook
    Dim XL As Excel.Application

    On Error GoTo ErrHandle
    
    If ActiveWorkbook Is Nothing Then
        Exit Sub
    End If
    
    If ActiveWorkbook.Path = "" Then
        MsgBox "元ブックのパスが取得できません。保存してから再度実行してください。", vbExclamation, C_TITLE
        Exit Sub
    End If

    Set FS = CreateObject("Scripting.FileSystemObject")

    If Left$(FS.getFileName(ActiveWorkbook.Name), 5) = C_REF_TEXT Then
        MsgBox "すでに参照用のブックが開かれています。", vbExclamation, C_TITLE
        Exit Sub
    End If
    
    Set Wb = ActiveWorkbook

    strActBook = ActiveWorkbook.FullName
    strTmpBook = rlxGetTempFolder() & C_REF_TEXT & FS.getFileName(ActiveWorkbook.Name)

    FS.CopyFile strActBook, strTmpBook

    Wb.Close

    Workbooks.Open FileName:=strTmpBook, ReadOnly:=True
    AppActivate Application.Caption
    
    Set FS = Nothing
    Set Wb = Nothing
    
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE
End Sub
'--------------------------------------------------------------
'　参照用ワークブック表示
'--------------------------------------------------------------
Public Sub OpenReferenceBook()

    Dim strActBook As String
    Dim strTmpBook As String
    Dim strFile As String
    
    On Error GoTo ErrHandle
    
    SetMyDocument
    strFile = Application.GetOpenFilename(, , "参照ワークブック選択", , False)
    If strFile = "False" Then
        'ファイル名が指定されなかった場合
        Exit Sub
    End If
    
    'ファイルの存在チェック
    If rlxIsFileExists(strFile) Then
    Else
        MsgBox "ファイルが存在しません。", vbExclamation, C_TITLE
        Exit Sub
    End If

    Dim blnResult As Boolean
    If frmReference.Start(blnResult) = vbCancel Then
        Exit Sub
    End If


    Dim FS As Object
    Dim Wb As Workbook
    Dim XL As Excel.Application

    Set FS = CreateObject("Scripting.FileSystemObject")

    strActBook = strFile
    strTmpBook = rlxGetTempFolder() & C_REF_TEXT & FS.getFileName(strFile)

    FS.CopyFile strActBook, strTmpBook

    If blnResult Then
        Set XL = New Excel.Application
        
        XL.visible = True
        
        Set Wb = XL.Workbooks.Open(FileName:=strTmpBook, ReadOnly:=True)
        AppActivate XL.Caption
    Else
        Set Wb = Workbooks.Open(FileName:=strTmpBook, ReadOnly:=True)
        AppActivate Application.Caption
    End If
    
    
    Set FS = Nothing

    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE
    
End Sub
'--------------------------------------------------------------
'　2003互換色(背景色)
'--------------------------------------------------------------
Sub LegacyBackColor()

    Dim lngColor As Long
    
    On Error GoTo ErrHandle
    
    If ActiveWorkbook Is Nothing Then
        MsgBox "アクティブなブックが見つかりません。", vbCritical, C_TITLE
        Exit Sub
    End If
    
    lngColor = Selection.Interior.Color
    If frmColor.Start(lngColor) = vbCancel Then
        Exit Sub
    End If
    
    Selection.Interior.Color = lngColor
    
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE

End Sub
'--------------------------------------------------------------
'　2003互換色(文字色)
'--------------------------------------------------------------
Sub LegacyFontColor()

    Dim lngColor As Long
    
    On Error GoTo ErrHandle
    
    If checkInit() <> vbOK Then
        Exit Sub
    End If
  
    lngColor = Selection.Font.Color
    If frmColor.Start(lngColor) = vbCancel Then
        Exit Sub
    End If
    
    Selection.Font.Color = lngColor
    
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE

End Sub
Private Function checkInit() As Long

    On Error GoTo ErrHandle

    If ActiveWorkbook Is Nothing Then
        MsgBox "アクティブなブックが見つかりません。", vbCritical, C_TITLE
        checkInit = vbCancel
        Exit Function
    End If
    
    checkInit = vbOK
    
    Exit Function
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE

End Function
'--------------------------------------------------------------
'　印刷プレビュー
'--------------------------------------------------------------
Sub execPreview()
    On Error Resume Next
    ActiveWindow.SelectedSheets.PrintOut preview:=True
End Sub
Sub verticalLine()

    Dim e As SelectionFormatBoader
    
    Set e = New SelectionFormatBoader
    
    e.BoadersIndex = xlInsideVertical
    e.LineStyle = xlContinuous
    e.Weight = xlThin
    
    e.Run
    
    Set e = Nothing
    
End Sub
'--------------------------------------------------------------
'　垂直線トグル
'--------------------------------------------------------------
Sub verticalLineToggle()
    On Error Resume Next
    setLineStyle Selection.Borders(xlInsideVertical)
End Sub
'--------------------------------------------------------------
'　枠線トグル
'--------------------------------------------------------------
Sub aroundLineToggle()

    Dim ret As Long
    On Error Resume Next
    With Selection.Borders(xlEdgeTop)
        Select Case True
            Case .LineStyle = xlLineStyleNone
                ret = 0
            Case .LineStyle = xlContinuous And .Weight = xlThin
                ret = 1
            Case Else
                ret = 2
        End Select
        
        ret = ret + 1
        If ret > 2 Then
            ret = 0
        End If
        
    End With
    
    With Selection.Borders(xlEdgeTop)
        Select Case ret
            Case 0
                .LineStyle = xlLineStyleNone
            Case 1
                .LineStyle = xlContinuous
                .Weight = xlThin
            Case Else
                .LineStyle = xlContinuous
                .Weight = xlMedium
        End Select
    End With
    With Selection.Borders(xlEdgeLeft)
        Select Case ret
            Case 0
                .LineStyle = xlLineStyleNone
            Case 1
                .LineStyle = xlContinuous
                .Weight = xlThin
            Case Else
                .LineStyle = xlContinuous
                .Weight = xlMedium
        End Select
    End With
    With Selection.Borders(xlEdgeRight)
        Select Case ret
            Case 0
                .LineStyle = xlLineStyleNone
            Case 1
                .LineStyle = xlContinuous
                .Weight = xlThin
            Case Else
                .LineStyle = xlContinuous
                .Weight = xlMedium
        End Select
    End With
    With Selection.Borders(xlEdgeBottom)
        Select Case ret
            Case 0
                .LineStyle = xlLineStyleNone
            Case 1
                .LineStyle = xlContinuous
                .Weight = xlThin
            Case Else
                .LineStyle = xlContinuous
                .Weight = xlMedium
        End Select
    End With
    
End Sub
'--------------------------------------------------------------
'　枠線トグル
'--------------------------------------------------------------
Sub tableLineToggle()

    Dim ret As Long
    On Error Resume Next
    With Selection.Borders(xlEdgeTop)
        Select Case True
            Case .LineStyle = xlLineStyleNone
                ret = 0
            Case Else
                ret = 1
        End Select
        
        ret = ret + 1
        If ret > 1 Then
            ret = 0
        End If
        
    End With
    
    With Selection.Borders(xlEdgeTop)
        Select Case ret
            Case 0
                .LineStyle = xlLineStyleNone
            Case Else
                .LineStyle = xlContinuous
                .Weight = xlThin
        End Select
    End With
    With Selection.Borders(xlEdgeLeft)
        Select Case ret
            Case 0
                .LineStyle = xlLineStyleNone
            Case Else
                .LineStyle = xlContinuous
                .Weight = xlThin
        End Select
    End With
    With Selection.Borders(xlEdgeRight)
        Select Case ret
            Case 0
                .LineStyle = xlLineStyleNone
            Case Else
                .LineStyle = xlContinuous
                .Weight = xlThin
        End Select
    End With
    With Selection.Borders(xlEdgeBottom)
        Select Case ret
            Case 0
                .LineStyle = xlLineStyleNone
            Case Else
                .LineStyle = xlContinuous
                .Weight = xlThin
        End Select
    End With
    With Selection.Borders(xlInsideHorizontal)
        Select Case ret
            Case 0
                .LineStyle = xlLineStyleNone
            Case Else
                .LineStyle = xlContinuous
                .Weight = xlThin
        End Select
    End With
End Sub
'--------------------------------------------------------------
'　枠線トグル
'--------------------------------------------------------------
Sub winLineToggle()
    Dim ret As Long
    On Error Resume Next
    With Selection.Borders(xlEdgeTop)
        Select Case True
            Case .LineStyle = xlLineStyleNone
                ret = 0
            Case Else
                ret = 1
        End Select
        
        ret = ret + 1
        If ret > 1 Then
            ret = 0
        End If
        
    End With
    
    With Selection.Borders(xlEdgeTop)
        Select Case ret
            Case 0
                .LineStyle = xlLineStyleNone
            Case Else
                .LineStyle = xlContinuous
                .Weight = xlThin
        End Select
    End With
    With Selection.Borders(xlEdgeLeft)
        Select Case ret
            Case 0
                .LineStyle = xlLineStyleNone
            Case Else
                .LineStyle = xlContinuous
                .Weight = xlThin
        End Select
    End With
    With Selection.Borders(xlEdgeRight)
        Select Case ret
            Case 0
                .LineStyle = xlLineStyleNone
            Case Else
                .LineStyle = xlContinuous
                .Weight = xlThin
        End Select
    End With
    With Selection.Borders(xlEdgeBottom)
        Select Case ret
            Case 0
                .LineStyle = xlLineStyleNone
            Case Else
                .LineStyle = xlContinuous
                .Weight = xlThin
        End Select
    End With
    With Selection.Borders(xlInsideHorizontal)
        Select Case ret
            Case 0
                .LineStyle = xlLineStyleNone
            Case Else
                .LineStyle = xlContinuous
                .Weight = xlThin
        End Select
    End With
    With Selection.Borders(xlInsideVertical)
        Select Case ret
            Case 0
                .LineStyle = xlLineStyleNone
            Case Else
                .LineStyle = xlContinuous
                .Weight = xlThin
        End Select
    End With
End Sub
'--------------------------------------------------------------
'　垂直線消去
'--------------------------------------------------------------
Sub verticalNoLine()

    Dim e As SelectionFormatBoader
    
    Set e = New SelectionFormatBoader
    
    e.BoadersIndex = xlInsideVertical
    e.LineStyle = xlNone
    
    e.Run
    
    Set e = Nothing
    
End Sub
'--------------------------------------------------------------
'　水平中線
'--------------------------------------------------------------
Sub HorizontalLine()
    
    Dim e As SelectionFormatBoader
    
    Set e = New SelectionFormatBoader
    
    e.BoadersIndex = xlInsideHorizontal
    e.LineStyle = xlContinuous
    e.Weight = xlThin
    
    e.Run
    
    Set e = Nothing
    
End Sub
'--------------------------------------------------------------
'　水平線トグル
'--------------------------------------------------------------
Sub HorizontalLineToggle()
    On Error Resume Next
    setLineStyle Selection.Borders(xlInsideHorizontal)
End Sub
'--------------------------------------------------------------
'　水平線消去
'--------------------------------------------------------------
Sub HorizontalNoLine()
    
    Dim e As SelectionFormatBoader
    
    Set e = New SelectionFormatBoader
    
    e.BoadersIndex = xlInsideHorizontal
    e.LineStyle = xlNone
    
    e.Run
    
    Set e = Nothing
    
End Sub
Private Sub setLineStyle(ByRef r As Border)

    Dim ret As Long

    On Error GoTo ErrHandle
    
    With r
        Select Case True
            Case .LineStyle = xlLineStyleNone
                ret = 0
            Case .LineStyle = xlContinuous And .Weight = xlHairline
                ret = 1
            Case Else
                ret = 2
        End Select
        
        ret = ret + 1
        If ret > 2 Then
            ret = 0
        End If
        
        Select Case ret
            Case 0
                .LineStyle = xlLineStyleNone
            Case 1
                .LineStyle = xlContinuous
                .Weight = xlHairline
            Case Else
                .LineStyle = xlContinuous
                .Weight = xlThin
        End Select
    End With
    
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE
End Sub
'--------------------------------------------------------------
'　ＭＳゴシック９ポイント文字列
'--------------------------------------------------------------
Sub documentSheet()

    Dim r As Range
    
    On Error Resume Next
    
    Set r = ActiveSheet.Cells

    r.NumberFormatLocal = "@"
    
    With r.Font
        .Name = "ＭＳ ゴシック"
        .FontStyle = "標準"
        .Size = 9
        .Strikethrough = False
        .Superscript = False
        .Subscript = False
        .OutlineFont = False
        .Shadow = False
        .Underline = xlUnderlineStyleNone
        .ThemeColor = xlThemeColorLight1
        .TintAndShade = 0
        .ThemeFont = xlThemeFontNone
    End With
    
End Sub
'--------------------------------------------------------------
'　メイリオ９ポイント文字列
'--------------------------------------------------------------
Sub documentSheetMeiryo()

    Dim r As Range
    
    On Error Resume Next
    
    Set r = ActiveSheet.Cells

    r.NumberFormatLocal = "@"
    
    With r.Font
        .Name = "メイリオ"
        .FontStyle = "標準"
        .Size = 9
        .Strikethrough = False
        .Superscript = False
        .Subscript = False
        .OutlineFont = False
        .Shadow = False
        .Underline = xlUnderlineStyleNone
        .ThemeColor = xlThemeColorLight1
        .TintAndShade = 0
        .ThemeFont = xlThemeFontNone
    End With
    
End Sub
'--------------------------------------------------------------
'　Meiryo UI ９ポイント文字列
'--------------------------------------------------------------
Sub documentSheetMeiryoUI()

    Dim r As Range
    
    On Error Resume Next
    
    Set r = ActiveSheet.Cells

    r.NumberFormatLocal = "@"
    
    With r.Font
        .Name = "Meiryo UI"
        .FontStyle = "標準"
        .Size = 9
        .Strikethrough = False
        .Superscript = False
        .Subscript = False
        .OutlineFont = False
        .Shadow = False
        .Underline = xlUnderlineStyleNone
        .ThemeColor = xlThemeColorLight1
        .TintAndShade = 0
        .ThemeFont = xlThemeFontNone
    End With
    
End Sub
'--------------------------------------------------------------
'　方眼紙幅２
'--------------------------------------------------------------
Sub documentSheetHogan2()

    Dim r As Range
    
    On Error Resume Next
    
    Set r = ActiveSheet.Cells
    r.NumberFormatLocal = "@"
    r.ColumnWidth = 2
    
End Sub
'--------------------------------------------------------------
'　ＭＳゴシック９ポイント方眼紙幅２
'--------------------------------------------------------------
Sub documentSheetHogan2Gothic9()

    Dim r As Range
    
    On Error Resume Next
    
    Set r = ActiveSheet.Cells
    r.NumberFormatLocal = "@"
    r.ColumnWidth = 2
    
    With r.Font
        .Name = "ＭＳ ゴシック"
        .FontStyle = "標準"
        .Size = 9
    End With
    
End Sub
'--------------------------------------------------------------
'　ＭＳゴシック９ポイント文字列方眼紙幅２
'--------------------------------------------------------------
Sub documentSheetHogan2Gothic9Str()

    Dim r As Range
    
    On Error Resume Next
    
    Set r = ActiveSheet.Cells

    r.NumberFormatLocal = "@"
    r.ColumnWidth = 2
    
    With r.Font
        .Name = "ＭＳ ゴシック"
        .FontStyle = "標準"
        .Size = 9
    End With
    
End Sub
'--------------------------------------------------------------
'　ＭＳゴシック１１ポイント方眼紙幅２
'--------------------------------------------------------------
Sub documentSheetHogan2Gothic11()

    Dim r As Range
    
    On Error Resume Next
    
    Set r = ActiveSheet.Cells
    r.NumberFormatLocal = "@"
    r.ColumnWidth = 2
    
    With r.Font
        .Name = "ＭＳ ゴシック"
        .FontStyle = "標準"
        .Size = 11
    End With
    
End Sub
'--------------------------------------------------------------
'　ＭＳゴシック１１ポイント文字列方眼紙幅２
'--------------------------------------------------------------
Sub documentSheetHogan2Gothic11Str()

    Dim r As Range
    
    On Error Resume Next
    
    Set r = ActiveSheet.Cells

    r.NumberFormatLocal = "@"
    r.ColumnWidth = 2
    
    With r.Font
        .Name = "ＭＳ ゴシック"
        .FontStyle = "標準"
        .Size = 11
    End With
    
End Sub
'--------------------------------------------------------------
'　ユーザ定義方眼紙
'--------------------------------------------------------------
Sub documentSheetUser()

    Dim r As Range
    Dim strFont As String
    Dim strPoint As String
    Dim strCol As String
    Dim strRow As String
    Dim blnBunrui As Boolean
    
    On Error Resume Next
    
    Set r = ActiveSheet.Cells

    blnBunrui = GetSetting(C_TITLE, "FormatCell", "Bunrui", False)
    strFont = GetSetting(C_TITLE, "FormatCell", "Font", "ＭＳ ゴシック")
    strPoint = GetSetting(C_TITLE, "FormatCell", "Point", "9")
    strCol = GetSetting(C_TITLE, "FormatCell", "Col", "8.5")
    strRow = GetSetting(C_TITLE, "FormatCell", "Row", "11.25")

    If blnBunrui Then
        r.NumberFormatLocal = "G/標準"
    Else
        r.NumberFormatLocal = "@"
    End If
    
    If GetSetting(C_TITLE, "FormatCell", "Size", False) Then
    
        r.ColumnWidth = Val(strCol)
        r.RowHeight = Val(strRow)
        
    End If
    
    With r.Font
        .Name = strFont
        .FontStyle = "標準"
        .Size = Val(strPoint)
        .Strikethrough = False
        .Superscript = False
        .Subscript = False
        .OutlineFont = False
        .Shadow = False
        .Underline = xlUnderlineStyleNone
        .ThemeColor = xlThemeColorLight1
        .TintAndShade = 0
        .ThemeFont = xlThemeFontNone
    End With
    
End Sub
'--------------------------------------------------------------
' 行列の入れ替え
'--------------------------------------------------------------
Sub selTranspose()

    Dim sourceRange As Range
    Dim destRange As Range
    Dim rr As Range
    Dim sel As Range

    On Error GoTo e

    Application.ScreenUpdating = False

    ThisWorkbook.Worksheets("Undo").Cells.Clear
    
    Set sourceRange = Selection
    Set destRange = ThisWorkbook.Worksheets("Undo").Range(Selection.Address)
    
    For Each rr In sourceRange.Areas
        rr.Copy destRange.Worksheet.Range(rr.Address)
    Next

    sourceRange.Clear

    For Each rr In destRange.Areas
        rr.Copy
        Dim lngPos As Long
        Dim s As String
        
        lngPos = InStr(rr.Address, ":")
        If lngPos = 0 Then
            s = rr.Address
        Else
            s = Mid(rr.Address, 1, lngPos - 1)
        End If
        sourceRange.Worksheet.Range(s).PasteSpecial Paste:=xlPasteAll, Operation:=xlNone, SkipBlanks:=False, Transpose:=True
        If sel Is Nothing Then
            Set sel = Selection
        Else
            Set sel = Union(sel, Selection)
        End If
    Next
    
    sel.Select
    Application.CutCopyMode = False
e:
    Application.ScreenUpdating = True

End Sub

'--------------------------------------------------------------
'　シート名をA1セルに貼り付け
'--------------------------------------------------------------
Sub setA1SheetName()

    On Error GoTo ErrHandle
    
    If ActiveWorkbook Is Nothing Then
        MsgBox "アクティブなブックが見つかりません。", vbCritical, C_TITLE
        Exit Sub
    End If
            
    If ActiveSheet Is Nothing Then
        MsgBox "アクティブなシートが見つかりません。", vbCritical, C_TITLE
        Exit Sub
    End If
    
    ActiveSheet.Cells(1, 1).value = ActiveSheet.Name

    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE

End Sub
'--------------------------------------------------------------
'　シート名をA1セルに貼り付け(ALL)
'--------------------------------------------------------------
Sub setA1SheetAll()

    Dim WS As Worksheet
    Dim strBuf As String
  
    On Error GoTo ErrHandle
    
    If ActiveWorkbook Is Nothing Then
        MsgBox "アクティブなブックが見つかりません。", vbCritical, C_TITLE
        Exit Sub
    End If
  
    strBuf = ""
    For Each WS In Worksheets
            
        If WS.visible = xlSheetVisible Then
            WS.Cells(1, 1).value = WS.Name
        End If
    Next

    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE

End Sub
'--------------------------------------------------------------
'　上選択
'--------------------------------------------------------------
Sub selectionTop()
    On Error GoTo ErrHandle
    Range(Selection, Selection.End(xlUp)).Select
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE
End Sub
'--------------------------------------------------------------
'　左選択
'--------------------------------------------------------------
Sub selectionLeft()
    On Error GoTo ErrHandle
    Range(Selection, Selection.End(xlToLeft)).Select
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE
End Sub
'--------------------------------------------------------------
'　右選択
'--------------------------------------------------------------
Sub selectionRight()
    On Error GoTo ErrHandle
    Range(Selection, Selection.End(xlToRight)).Select
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE
End Sub
'--------------------------------------------------------------
'　下選択
'--------------------------------------------------------------
Sub selectionDown()
    On Error GoTo ErrHandle
    Range(Selection, Selection.End(xlDown)).Select
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE
End Sub
'--------------------------------------------------------------
'　左上選択
'--------------------------------------------------------------
Sub selectionLeftTop()
    On Error GoTo ErrHandle
    Range(Selection, Selection.End(xlUp)).Select
    Range(Selection, Selection.End(xlToLeft)).Select
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE
End Sub
'--------------------------------------------------------------
'　右下選択
'--------------------------------------------------------------
Sub selectionRightDown()
    On Error GoTo ErrHandle
    Range(Selection, Selection.End(xlToRight)).Select
    Range(Selection, Selection.End(xlDown)).Select
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE
End Sub
'--------------------------------------------------------------
'　タグジャンプ（カーソル位置の情報からExcelを開きセルを選択）
'--------------------------------------------------------------
Sub tagJump()

    Const C_SEARCH_NO As Long = 1
    Const C_SEARCH_BOOK As Long = 2
    Const C_SEARCH_SHEET As Long = 3
    Const C_SEARCH_ADDRESS As Long = 4
    Const C_SEARCH_STR As Long = 5

    Dim Wb As Workbook
    Dim WS As Worksheet
    Dim strBook As String
    Dim strSheet As String
    Dim strAddress As String

    On Error GoTo ErrHandle
    
    If ActiveWorkbook Is Nothing Then
        Exit Sub
    End If

    strBook = Cells(ActiveCell.row, C_SEARCH_BOOK).value
    If Len(strBook) = 0 Then
        Exit Sub
    End If
    strSheet = Cells(ActiveCell.row, C_SEARCH_SHEET).value
    If Len(strSheet) = 0 Then
        Exit Sub
    End If
    strAddress = Cells(ActiveCell.row, C_SEARCH_ADDRESS).value
    If Len(strAddress) = 0 Then
        Exit Sub
    End If

    On Error Resume Next
    Set Wb = Workbooks.Open(FileName:=strBook)
    AppActivate Application.Caption

    Set WS = Wb.Worksheets(strSheet)
    WS.Select
    
    WS.Range(strAddress).Select
    WS.Shapes.Range(strAddress).Select

    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE
End Sub
'--------------------------------------------------------------
'　選択範囲の復元
'--------------------------------------------------------------
Sub saveRange()

    Dim strBuf As String
    Dim strBuf2 As String
    
    Dim strRange() As String
    Dim strSaveRange As String
    Dim lngCount As Long
    Dim i As Long
    
    On Error GoTo ErrHandle
    
    strSaveRange = Selection.Address(RowAbsolute:=False, ColumnAbsolute:=False)
    strBuf = strSaveRange
    
    strBuf2 = GetSetting(C_TITLE, "ReSelect", "Range", "")
    strRange = Split(strBuf2, vbTab)
    
    lngCount = 1
    For i = LBound(strRange) To UBound(strRange)
        If strRange(i) <> strSaveRange Then
            strBuf = strBuf & vbTab & strRange(i)
            lngCount = lngCount + 1
            'リストは最大１０
            If lngCount >= 10 Then
                Exit For
            End If
        End If
    Next
    SaveSetting C_TITLE, "ReSelect", "Range", strBuf
    
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE
End Sub
'--------------------------------------------------------------
'　お気に入りの追加
'--------------------------------------------------------------
Sub addFavorite()

    Dim strBuf As String
    
    Dim strBooks() As String
    Dim strBook As String
    Dim lngCount As Long
    Dim i As Long
    
    On Error GoTo ErrHandle
    
    If ActiveWorkbook Is Nothing Then
        Exit Sub
    End If
    
    strBook = ActiveWorkbook.FullName
    
    If Not rlxIsFileExists(strBook) Then
        MsgBox "ブックが存在しません。保存してから処理を行ってください。", vbOKOnly + vbExclamation, C_TITLE
        Exit Sub
    End If

    strBuf = GetSetting(C_TITLE, "Favirite", "FileList", "")
    strBooks = Split(strBuf, vbVerticalTab)
    
    For i = LBound(strBooks) To UBound(strBooks)
        If LCase(Split(strBooks(i), vbTab)(0)) = LCase(strBook) Then
            MsgBox "すでに登録されています。", vbOKOnly + vbExclamation, C_TITLE
            Exit Sub
        End If
    Next
    
    If Len(strBuf) = 0 Then
        strBuf = strBook
    Else
        strBuf = strBuf & vbVerticalTab & strBook
    End If
    
    SaveSetting C_TITLE, "Favirite", "FileList", strBuf
    
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE
    
End Sub
'--------------------------------------------------------------
'　次ワークシート表示
'--------------------------------------------------------------
Sub nextWorksheet()

    Dim i As Long
    
    On Error GoTo ErrHandle
    
    If ActiveSheet Is Nothing Then
        Exit Sub
    End If
    
    For i = ActiveSheet.Index + 1 To ActiveWorkbook.Worksheets.count
        If ActiveWorkbook.Worksheets(i).visible = xlSheetVisible Then
            ActiveWorkbook.Worksheets(i).Select
            Exit For
        End If
    Next
    
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE
End Sub
'--------------------------------------------------------------
'　前ワークシート表示
'--------------------------------------------------------------
Sub prevWorksheet()
    
    Dim i As Long
    
    On Error GoTo ErrHandle
    
    If ActiveSheet Is Nothing Then
        Exit Sub
    End If
    For i = ActiveSheet.Index - 1 To 1 Step -1
        If ActiveWorkbook.Worksheets(i).visible = xlSheetVisible Then
            ActiveWorkbook.Worksheets(i).Select
            Exit For
        End If
    Next
    
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE
End Sub
'--------------------------------------------------------------
'　次ワークブック表示
'--------------------------------------------------------------
Sub nextWorkbook()

    Dim i As Long
    Dim blnFind As Boolean
    
    On Error GoTo ErrHandle
    
    If ActiveWorkbook Is Nothing Then
        Exit Sub
    End If
    
    blnFind = False
    
    For i = 1 To Workbooks.count
        If blnFind Then
            Workbooks(i).Activate
            Exit For
        End If
        If UCase(ActiveWorkbook.Name) = UCase(Workbooks(i).Name) Then
            blnFind = True
        End If
    Next
    
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE
End Sub
'--------------------------------------------------------------
'　前ワークブック表示
'--------------------------------------------------------------
Sub prevWorkbook()

    Dim i As Long
    Dim blnFind As Boolean
    
    On Error GoTo ErrHandle
    
    If ActiveWorkbook Is Nothing Then
        Exit Sub
    End If
    
    blnFind = False
    
    For i = Workbooks.count To 1 Step -1
        If blnFind Then
            Workbooks(i).Activate
            Exit For
        End If
        If UCase(ActiveWorkbook.Name) = UCase(Workbooks(i).Name) Then
            blnFind = True
        End If
    Next
    
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE
End Sub
'--------------------------------------------------------------
'　目次作成
'--------------------------------------------------------------
Sub createContentsEx()

    Const C_NAME As String = "目次"
    Const C_NO As Long = 1
    Const C_SHEET_NAME As Long = 2
    Const C_PAPER_SIZE As Long = 3
    Const C_PAGES As Long = 4
    Const C_HEAD_ROW = 2
    Const C_START_ROW = 3

    Dim Wb As Workbook
    Dim WS As Worksheet
    Dim s As Worksheet
    Dim lngCount As Long

    Set Wb = ActiveWorkbook
    
    'シートの存在チェック
    For Each s In Wb.Worksheets
        If s.Name = C_NAME Then
            If MsgBox("「" & C_NAME & "」シートが既に存在します。削除していいですか？", vbOKCancel + vbQuestion, C_TITLE) <> vbOK Then
                Exit Sub
            Else
                '存在する場合は削除
                Application.DisplayAlerts = False
                s.Delete
                Application.DisplayAlerts = True
            End If
        End If
    Next
    
    On Error GoTo e
    
    Application.ScreenUpdating = False
    Set WS = Wb.Worksheets.Add(Wb.Worksheets(1))
    WS.Name = C_NAME
    
    WS.Cells(1, 1).value = "ブック名:" & Wb.Name
    
    lngCount = C_START_ROW
    WS.Cells(lngCount, C_NO).value = "No."
    WS.Cells(lngCount, C_SHEET_NAME).value = "シート名"
    WS.Cells(lngCount, C_PAPER_SIZE).value = "用紙"
    WS.Cells(lngCount, C_PAGES).value = "ページ数"
    
    lngCount = lngCount + 1
    
    For Each s In Wb.Worksheets
    
        If s.Name <> C_NAME Then
        
            If s.visible = xlSheetVisible Then
        
                WS.Cells(lngCount, C_NO).value = lngCount - C_START_ROW
                WS.Cells(lngCount, C_SHEET_NAME).value = s.Name
                
                WS.Hyperlinks.Add _
                    Anchor:=WS.Cells(lngCount, C_SHEET_NAME), _
                    Address:="", _
                    SubAddress:="'" & s.Name & "'!" & s.Cells(1, 1).Address, _
                    TextToDisplay:=s.Name
                
                Select Case s.PageSetup.PaperSize
                    Case xlPaperA3
                        WS.Cells(lngCount, C_PAPER_SIZE).value = "A3"
                    Case xlPaperA4
                        WS.Cells(lngCount, C_PAPER_SIZE).value = "A4"
                    Case xlPaperA5
                        WS.Cells(lngCount, C_PAPER_SIZE).value = "A5"
                    Case xlPaperB4
                        WS.Cells(lngCount, C_PAPER_SIZE).value = "B4"
                    Case xlPaperB5
                        WS.Cells(lngCount, C_PAPER_SIZE).value = "B5"
                    Case Else
                        WS.Cells(lngCount, C_PAPER_SIZE).value = "その他"
                End Select
                WS.Cells(lngCount, C_PAGES).value = s.PageSetup.Pages.count
            
                lngCount = lngCount + 1
            End If
        End If
    Next

    WS.Columns("A").ColumnWidth = 5
    WS.Columns("B:D").AutoFit
    Dim r As Range
    Set r = WS.Cells(C_START_ROW, 1).CurrentRegion
    
    r.VerticalAlignment = xlTop
    r.Select
    
    execSelectionRowDrawGrid
    
    WS.Cells(lngCount, C_PAPER_SIZE).value = "合計"
    WS.Cells(lngCount, C_PAGES).value = "=SUM(D" & C_START_ROW + 1 & ":D" & lngCount - 1 & ")"

e:
    Application.ScreenUpdating = True
    Set r = Nothing

    Set WS = Nothing
    Set Wb = Nothing

End Sub
'--------------------------------------------------------------
'　外部エディタ編集
'--------------------------------------------------------------
Sub cellEditExt()

    Dim strFileName As String
    Dim bytBuf() As Byte
    Const C_FF As Byte = &HFF
    Const C_FE As Byte = &HFE
    Dim strBuf As String
    Dim fp As Integer
    Dim lngSize As Long
    Dim WSH As Object
    Dim FS As Object
    Dim strBefore As String
    Dim strAfter As String
    Dim blnBOM As Boolean
    Dim strEditor As String
    Dim r As Range
    
    Dim strEncode As String
    
    On Error GoTo e
    
    If ActiveCell Is Nothing Then
        Exit Sub
    End If
    
'    If selection.count > 1 And selection.count <> selection(1, 1).MergeArea.count Then
    If Selection.CountLarge > 1 And Selection.CountLarge <> Selection(1, 1).MergeArea.count Then
        MsgBox "複数セル選択されています。セルは１つのみ選択してください。", vbExclamation + vbOKOnly, C_TITLE
        Exit Sub
    End If
    
    frmInformation.Message = "外部エディタ起動中です。作業を継続する場合には外部エディタを終了してください。"
    frmInformation.Show
    
    Set r = ActiveCell
    
    Dim strNotepad As String

    Set FS = CreateObject("Scripting.FileSystemObject")
    strNotepad = rlxAddFileSeparator(FS.GetSpecialFolder(0)) & "notepad.exe"
    
    strEditor = GetSetting(C_TITLE, "EditEx", "Editor", strNotepad)
    strEncode = GetSetting(C_TITLE, "EditEx", "Encode", C_SJIS)
    blnBOM = GetSetting(C_TITLE, "EditEx", "BOM", False)
    
    Dim utf8 As UTF8Encoding
    
    strBuf = Replace(Replace(r.Formula, vbCrLf, vbLf), vbLf, vbCrLf)
    
    Select Case strEncode
        Case C_UTF16
            bytBuf = strBuf
        Case C_UTF8
            Set utf8 = New UTF8Encoding
            bytBuf = utf8.getBytes(strBuf)
        Case Else
            bytBuf = StrConv(strBuf, vbFromUnicode)
    End Select
    
    
    strFileName = rlxGetTempFolder() & "ActiveCell.tmp"
    
    fp = FreeFile()
    Open strFileName For Output As #fp
    Close fp
    
    fp = FreeFile()
    Open strFileName For Binary As #fp
    If blnBOM Then
        Put fp, , C_FF
        Put fp, , C_FE
    End If
    Put fp, , bytBuf
    Close fp
    
    strBefore = FS.GetFile(strFileName).DateLastModified
 
    Set WSH = CreateObject("WScript.Shell")
    
    On Error Resume Next
    Call WSH.Run("""" & strEditor & """ " & """" & strFileName & """", 1, True)
    If err.Number <> 0 Then
        MsgBox "エディタの起動に失敗しました。設定を確認してください。", vbOKOnly + vbExclamation, C_TITLE
        GoTo e
    End If
    
    On Error GoTo e
    
    Set WSH = Nothing

    strAfter = FS.GetFile(strFileName).DateLastModified

    '変更されている場合
    If strBefore <> strAfter Then

        fp = FreeFile()
        Open strFileName For Binary As #fp
        
        lngSize = LOF(fp)
        
        If lngSize <> 0 Then
        
            ReDim bytBuf(0 To lngSize - 1)
            Get fp, , bytBuf
            
            If UBound(bytBuf) - LBound(bytBuf) + 1 >= 2 Then
                'BOMが含まれている場合削除
                If bytBuf(0) = C_FF And bytBuf(1) = C_FE Then
                    bytBuf = MidB(bytBuf, 3)
                End If
            End If
            
            Select Case strEncode
                Case C_UTF16
                    strBuf = bytBuf
                Case C_UTF8
                    strBuf = utf8.GetString(bytBuf)
                Case Else
                    strBuf = StrConv(bytBuf, vbUnicode)
            End Select
            
            On Error Resume Next
            err.Clear
            r.Formula = Replace(strBuf, vbCrLf, vbLf)
            If err.Number <> 0 Then
                MsgBox "式の設定に失敗しました。式が正しくない可能性があります。", vbOKOnly + vbExclamation, C_TITLE
            End If
        Else
            r.Formula = ""
        End If
        Close fp
    
    End If
    
e:
    On Error Resume Next
    Close
    
    Set FS = Nothing
    Set utf8 = Nothing
    
    Kill strFileName
    
    Unload frmInformation
    
End Sub
'--------------------------------------------------------------
'　選択画像の保存
'--------------------------------------------------------------
Public Sub saveImage()

    Dim m_Width As Double, m_Height As Double
    Dim m_SavePath As String
    Dim argSavePath As String
    Dim strExt As String
    
    On Error GoTo ErrHandle
    
    If LCase(TypeName(Selection)) <> "picture" Then
        MsgBox "画像を１つ選択してください。", vbOKOnly + vbExclamation, C_TITLE
        Exit Sub
    End If
    
    argSavePath = Application.GetSaveAsFilename(, "PNGファイル(*.png), *.png,JPEGファイル(*.jpg), *.jpg,GIFファイル(*.gif), *.gif")
    If argSavePath = "False" Then
        Exit Sub
    End If
    
    If Len(argSavePath) > 0 Then
        Application.ScreenUpdating = False
        
        Selection.CopyPicture xlScreen, xlBitmap
        ActiveSheet.Paste
        With Selection
            m_Width = .Width: m_Height = .Height
            .CopyPicture xlScreen, xlBitmap
            .Delete
        End With
        
        On Error Resume Next
        With ActiveSheet.ChartObjects.Add(0, 0, m_Width, m_Height).Chart
            .Paste
            .ChartArea.Border.LineStyle = 0
            .Export argSavePath, UCase(Right$(argSavePath, 3))
            .Parent.Delete
        End With
        On Error GoTo 0
        
        Application.ScreenUpdating = True
    End If
    
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE
End Sub
'--------------------------------------------------------------
'　選択範囲の交換
'--------------------------------------------------------------
Sub swapAreas()

    '変数宣言
    Dim r As Range
    Dim blnRange As Boolean
    
    blnRange = False
    Select Case True
        Case ActiveWorkbook Is Nothing
        Case ActiveCell Is Nothing
        Case Selection Is Nothing
        Case TypeOf Selection Is Range
            blnRange = True
        Case Else
    End Select
    If blnRange Then
    Else
        MsgBox "選択範囲が見つかりません。", vbCritical, C_TITLE
        Exit Sub
    End If

    If Selection.CountLarge > C_MAX_CELLS Then
        MsgBox "大量のセルが選択されています。 " & C_MAX_CELLS & "以下にしてください。", vbExclamation + vbOKOnly, C_TITLE
        Exit Sub
    End If
    
    If Selection.Areas.count <> 2 Then
        MsgBox "２つの範囲を選択してください。", vbExclamation + vbOKOnly, C_TITLE
        Exit Sub
    End If
    
    If Selection.Areas(1).Rows.count <> Selection.Areas(2).Rows.count Or _
       Selection.Areas(1).Columns.count <> Selection.Areas(2).Columns.count Then
        MsgBox "２つの範囲の縦横サイズは同じにしてください。", vbExclamation + vbOKOnly, C_TITLE
        Exit Sub
    End If
    

    Dim strAddress As String
    
    strAddress = Selection.Address
    
    ThisWorkbook.Worksheets("Undo").Cells.Clear
    
    Set mUndo.sourceRange = Selection
    Set mUndo.destRange = ThisWorkbook.Worksheets("Undo").Range(Selection.Address)
    
    Dim rr As Range
    For Each rr In mUndo.sourceRange.Areas
        rr.Copy mUndo.destRange.Worksheet.Range(rr.Address)
    Next
    
    On Error Resume Next
    
    Application.ScreenUpdating = False
    
    'エリアを交換する。
    mUndo.destRange.Worksheet.Range(mUndo.sourceRange.Areas(2).Address).Copy mUndo.sourceRange.Areas(1)
    mUndo.destRange.Worksheet.Range(mUndo.sourceRange.Areas(1).Address).Copy mUndo.sourceRange.Areas(2)
    
    Application.ScreenUpdating = True
    
    ActiveSheet.Range(strAddress).Select
    
    'Undo
    Application.OnUndo "Undo", "execUndo"
    
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE
End Sub
'--------------------------------------------------------------
'  何もしない関数(キー無効用)
'--------------------------------------------------------------
Sub nop()

End Sub
'--------------------------------------------------------------
'　ショートカットキー初期設定
'--------------------------------------------------------------
Sub setShortCutKey()
    
    Dim strList() As String
    Dim strkey() As String
    Dim strResult As String
    Dim lngMax As Long
    Dim i As Long
    
    Const C_ON As String = "1"
    
    On Error GoTo ErrHandle
    
    strResult = GetSetting(C_TITLE, "ShortCut", "KeyList", "")
    strList = Split(strResult, vbVerticalTab)

    lngMax = UBound(strList)

    For i = 0 To lngMax
        strkey = Split(strList(i) & vbTab & C_ON, vbTab)
        If strkey(6) = C_ON Then
            If InStr(strkey(5), "RunMso") > 0 Then
                Application.OnKey strkey(2), strkey(5)
            Else
                Application.OnKey strkey(2), "'execOnKey """ & strkey(5) & """,""" & strkey(4) & """'"
            End If
        End If
    Next
    
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE
End Sub
'--------------------------------------------------------------
'　ショートカットキーの削除
'--------------------------------------------------------------
Sub removeShortCutKey()

    Dim strList() As String
    Dim strkey() As String
    Dim strResult As String
    Dim lngMax As Long
    Dim i As Long
    
    On Error Resume Next

'    'キー情報の削除
    strResult = GetSetting(C_TITLE, "ShortCut", "KeyList", "")
    strList = Split(strResult, vbVerticalTab)

    lngMax = UBound(strList)

    For i = 0 To lngMax
        strkey = Split(strList(i), vbTab)
        Application.OnKey strkey(2)
    Next

End Sub
'--------------------------------------------------------------
'　改ページの追加
'--------------------------------------------------------------
Sub addPageBreak()

    On Error Resume Next

    ActiveWindow.SelectedSheets.HPageBreaks.Add Before:=ActiveCell

End Sub
'--------------------------------------------------------------
'　改ページの全削除
'--------------------------------------------------------------
Sub resetPageBreak()

    On Error Resume Next

    ActiveSheet.ResetAllPageBreaks

End Sub
'--------------------------------------------------------------
'　改ページの削除
'--------------------------------------------------------------
Sub removePageBreak()

    On Error Resume Next

    Dim p As HPageBreak
    
    For Each p In ActiveWindow.SelectedSheets.HPageBreaks
        If p.Location.row = ActiveCell.row Then
            p.Delete
            Exit For
        End If
    Next
    
End Sub
'--------------------------------------------------------------
'　クリップボードからファイル名の貼り付け
'--------------------------------------------------------------
Sub getFileNameFromClipboard()

    Dim files As Variant
    Dim strBuf As String
    
    On Error GoTo ErrHandle
  
    If ActiveCell Is Nothing Then
        Exit Sub
    End If
    
    strBuf = rlxGetFileNameFromCli()
    
    If strBuf = "" Then
        Exit Sub
    End If
    
    files = Split(strBuf, vbTab)
    
    Dim i As Long
    For i = LBound(files) To UBound(files) Step 1
        ActiveCell.Offset(i, 0).value = files(i)
    Next
    
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE

End Sub
'--------------------------------------------------------------
'　クリップボードのExcelファイルを開く
'--------------------------------------------------------------
Sub openFileNameFromClipboard()

    Dim strActBook As String
    Dim strTmpBook As String

    Dim FS As Object
    Dim Wb As Workbooks
    Dim XL As Excel.Application

    On Error GoTo ErrHandle
    Dim files As Variant
    Dim strBuf As String
    Dim f As Variant
    
    On Error GoTo ErrHandle
  
    strBuf = rlxGetFileNameFromCli()
    
    If strBuf = "" Then
        Exit Sub
    End If
    
    files = Split(strBuf, vbTab)
    
    If IsEmpty(files) Then
        Exit Sub
    End If
    
    If UBound(files) + 1 > 10 Then
        If MsgBox(UBound(files) + 1 & "ファイル指定されています。続行しますか？", vbOKCancel + vbQuestion, C_TITLE) <> vbOK Then
            Exit Sub
        End If
    End If
    
    Dim blnResult As Boolean
    If frmReference.Start(blnResult) = vbCancel Then
        Exit Sub
    End If
        
    If blnResult Then
        Set XL = New Excel.Application
        XL.visible = True
        Set Wb = XL.Workbooks
    Else
        Set Wb = Workbooks
    End If
    
    Set FS = CreateObject("Scripting.FileSystemObject")
    
    For Each f In files
    
        If Not FS.FileExists(f) Then
            GoTo pass
        End If
            
        If Not rlxIsExcelFile(f) Then
            GoTo pass
        End If
            
        strTmpBook = rlxGetTempFolder() & C_REF_TEXT & FS.getFileName(f)
    
        FS.CopyFile f, strTmpBook
    
        Wb.Open FileName:=strTmpBook, ReadOnly:=True
pass:
    Next
    
    Set FS = Nothing
    
    Exit Sub
ErrHandle:
    MsgBox "エラーが発生しました。", vbOKOnly, C_TITLE

End Sub
'--------------------------------------------------------------
'　現在のExcelファイルをクリップボードに貼り付け
'--------------------------------------------------------------
Sub copyCurrentExcel()

    Dim strFiles() As String
    Dim strFile As String
    
    strFile = ActiveWorkbook.FullName

    If (Not rlxIsFileExists(strFile)) Then
        MsgBox "ブックが保存されていないようです。" & vbCrLf & "クリップボードへのコピーを中断しました。", vbOKOnly + vbExclamation, C_TITLE
        Exit Sub
    End If
    
    If ActiveWorkbook.Saved = False Then
        If MsgBox("ブックに変更があります。保存しますか？", vbYesNo + vbQuestion, C_TITLE) = vbYes Then
            ActiveWorkbook.Save
        End If
    End If
        
    strFiles = Split(strFile, vbTab)
    SetCopyClipText strFiles
    
    MsgBox ActiveWorkbook.Name & "をクリップボードにコピーしました。", vbOKOnly + vbInformation, C_TITLE

End Sub
'--------------------------------------------------------------
' 相対⇔絶対参照判定
'--------------------------------------------------------------
Function rlxGetFomuraRefType() As XlReferenceType

    Dim r As Range
    Dim lngExistRow As Long
    Dim lngExistCol As Long
    Dim strForm As String
    Dim i As Long
    
    '不明の場合とりあえず、相対参照
    rlxGetFomuraRefType = xlRelative
    
    On Error Resume Next
    
    For Each r In Selection

        If r.Rows.Hidden = False And r.Columns.Hidden = False Then

            Select Case Left(r.FormulaLocal, 1)
                '式の場合
                Case "=", "+"
                    strForm = r.FormulaLocal
                    
                    Dim blnSw As Boolean
                    Dim blnFind As Boolean
                    blnSw = False
                    blnFind = False
                    
                    For i = 1 To Len(strForm)
                
                        Dim strChr As String
                        
                        strChr = Mid$(strForm, i, 1)
                        Select Case strChr
                            Case """"
                                If blnSw Then
                                    blnSw = False
                                Else
                                    blnSw = True
                                End If
                                
                                blnFind = False
                            Case "$"
                                blnFind = True
                            Case Else
                                If blnFind Then
                                    Select Case strChr
                                        Case "A" To "Z"
                                            lngExistCol = lngExistCol + 1
                                        Case "0" To "9"
                                            lngExistRow = lngExistRow + 1
                                    End Select
                                End If
                            
                                blnFind = False
                        End Select
                
                    Next
                    
                    Select Case True
                        Case lngExistCol > 0 And lngExistRow > 0
                            rlxGetFomuraRefType = xlAbsolute
                        Case lngExistCol > 0
                            rlxGetFomuraRefType = xlRelRowAbsColumn
                        Case lngExistRow > 0
                            rlxGetFomuraRefType = xlAbsRowRelColumn
                        Case Else
                            rlxGetFomuraRefType = xlRelative
                    End Select
                    
                    Exit Function
                Case Else
            End Select
            
        End If
    Next
                    
End Function
'--------------------------------------------------------------
' 相対⇔絶対トグル
'--------------------------------------------------------------
Sub toggleAbsoluteFomura()

    Dim ref As XlReferenceType

    On Error Resume Next

    ref = rlxGetFomuraRefType()

    Select Case ref
        Case xlAbsolute
            execSelectionToAbsRowRelColumn
        Case xlRelRowAbsColumn
            execSelectionToRelative
        Case xlAbsRowRelColumn
            execSelectionToRelRowAbsColumn
        Case xlRelative
            execSelectionToAbsolute
    End Select

End Sub
'--------------------------------------------------------------
' A1⇔R1C1トグル
'--------------------------------------------------------------
Sub toggleReferenceStyle()

    On Error Resume Next

    If Application.ReferenceStyle = xlA1 Then
        Application.ReferenceStyle = xlR1C1
    Else
        Application.ReferenceStyle = xlA1
    End If

End Sub
'--------------------------------------------------------------
' 名前の表示
'--------------------------------------------------------------
Public Sub VisibleNames()

    Dim n As Object
    
    For Each n In ActiveWorkbook.Names
        If n.visible = False Then
            n.visible = True
        End If
    Next
    
    MsgBox "すべての名前の定義を表示しました。", vbOKOnly + vbInformation, C_TITLE

End Sub
'--------------------------------------------------------------
' まとめ実行１
'--------------------------------------------------------------
Sub execMatome01()

    execMatome "1"

End Sub
'--------------------------------------------------------------
' まとめ実行２
'--------------------------------------------------------------
Sub execMatome02()

    execMatome "2"

End Sub
'--------------------------------------------------------------
' まとめ実行３
'--------------------------------------------------------------
Sub execMatome03()

    execMatome "3"

End Sub
'--------------------------------------------------------------
' まとめ実行４
'--------------------------------------------------------------
Sub execMatome04()

    execMatome "4"

End Sub
'--------------------------------------------------------------
' まとめ実行５
'--------------------------------------------------------------
Sub execMatome05()

    execMatome "5"

End Sub
'--------------------------------------------------------------
' まとめ実行本体
'--------------------------------------------------------------
Private Sub execMatome(ByVal strNo As String)
    
    Dim strResult As String
    Dim varLine As Variant
    Dim varCol As Variant
    Dim i As Long
    
    strResult = GetSetting(C_TITLE, "Combo", "ComboList" & strNo, "")
        
    varLine = Split(strResult, vbVerticalTab)
        
    For i = LBound(varLine) To UBound(varLine)
        varCol = Split(varLine(i), vbTab)
        Application.Run varCol(3)
    Next

End Sub
'--------------------------------------------------------------
' Excel機能実行
'--------------------------------------------------------------
Sub RunMso(ByVal strMso As String)

    On Error Resume Next
    
    Application.CommandBars.ExecuteMso strMso

End Sub
'--------------------------------------------------------------
' レジストリのExport
'--------------------------------------------------------------
Sub RegExport()

    Dim strDat As String
    Const C_FF As Byte = &HFF
    Const C_FE As Byte = &HFE
    Dim FileName As Variant
    Dim strReg As String
    
    Dim Reg, Locator, Service, SubKey, RegName, RegType
    Dim i As Long, j As Long, buf As String, RegData As String
    
    Dim fp As Integer
    
    SetMyDocument
    
    FileName = Application.GetSaveAsFilename(InitialFileName:="RelaxTools-Addin.reg", FileFilter:="登録ファイル,*.reg")
    If FileName = False Then
        Exit Sub
    End If
    
    On Error GoTo err_Handle

    strReg = "HKEY_CURRENT_USER\SOFTWARE\VB and VBA Program Settings\RelaxTools-Addin"

    Set Locator = CreateObject("WbemScripting.SWbemLocator")
    Set Service = Locator.ConnectServer(vbNullString, "root\default")
    Set Reg = Service.get("StdRegProv")
    
    Const HKEY_CURRENT_USER = &H80000001
    
    Const ROOT = "HKEY_CURRENT_USER\"
    Const KEY = "SOFTWARE\VB and VBA Program Settings\RelaxTools-Addin"
    
    Reg.EnumKey HKEY_CURRENT_USER, KEY, SubKey
    
    fp = FreeFile()
    Open FileName For Output As fp
    Close fp
    
    fp = FreeFile()
    Open FileName For Binary As fp
    
    Dim strBuf() As Byte
    
    Put fp, , C_FF
    Put fp, , C_FE
    
    strBuf = "Windows Registry Editor Version 5.00" & vbCrLf & vbCrLf
    Put fp, , strBuf
    
    strBuf = "[" & ROOT & KEY & "]" & vbCrLf
    Put fp, , strBuf
    
    For i = 0 To UBound(SubKey)
        
        Reg.EnumValues HKEY_CURRENT_USER, KEY & "\" & SubKey(i), RegName, RegType
            
        strBuf = vbCrLf & "[" & ROOT & KEY & "\" & SubKey(i) & "]" & vbCrLf
        Put fp, , strBuf
        
        For j = 0 To UBound(RegName)
        
            Select Case RegType(j)
                Case 1
                    Reg.GetStringValue HKEY_CURRENT_USER, KEY & "\" & SubKey(i), RegName(j), RegData
                Case Else
                    Reg.GetMultiStringValue HKEY_CURRENT_USER, KEY & "\" & SubKey(i), RegName(j), RegData
                
            End Select
        
            strDat = Replace(RegData, "\", "\\")
            
            strBuf = """" & RegName(j) & """=""" & strDat & """" & vbCrLf
            
            Put fp, , strBuf
        
        Next j
        
    Next i
    strBuf = vbCrLf
    Put fp, , strBuf
    Close fp
    
    Set Reg = Nothing
    Set Service = Nothing
    Set Locator = Nothing
    
    MsgBox "登録ファイルを保存しました。" & vbCrLf & "移行先で登録ファイルを実行するとレジストリに反映されます。", vbOKOnly + vbInformation, C_TITLE
    Exit Sub
err_Handle:
    MsgBox "登録ファイルの保存に失敗しました。", vbOKOnly + vbInformation, C_TITLE
    
End Sub


