Attribute VB_Name = "basFusen"
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

Public Const C_FUSEN_DATE_SYSTEM As String = "1"
Public Const C_FUSEN_DATE_USER As String = "2"



'--------------------------------------------------------------
'　画像張付設定画面
'--------------------------------------------------------------
Sub showFusenSetting()

    frmFusen.Show
    
End Sub
'--------------------------------------------------------------
'　付箋管理画面
'--------------------------------------------------------------
Sub searchFusen()

    frmSearchFusen.Show
    
End Sub
'--------------------------------------------------------------
'　付箋設定値取得
'--------------------------------------------------------------
Sub getSettingFusen(ByRef strText As String, ByRef strTag As String, ByRef varPrint As Variant, ByRef strWidth As String, ByRef strHeight As String, ByRef strFormat As String, ByRef strUserDate As String, ByRef strFusenDate As String, ByRef strFont As String, ByRef strSize As String, ByRef varHorizontalAnchor As Variant, ByRef varVerticalAnchor As Variant, ByRef varAutoSize As Variant, ByRef varOverFlow As Variant, ByRef varWordWrap As Variant)

    strTag = GetSetting(C_TITLE, "Fusen", "Tag", "付箋検索用文字列")
    strText = GetSetting(C_TITLE, "Fusen", "Text", "$d" & " " & "$u" & vbCrLf & "【メモをここに入力してください】")
    varPrint = GetSetting(C_TITLE, "Fusen", "PrintObject", True)

    strWidth = GetSetting(C_TITLE, "Fusen", "Width", "7.5")
    strHeight = GetSetting(C_TITLE, "Fusen", "Height", "2.5")
    
    strUserDate = GetSetting(C_TITLE, "Fusen", "UserDate", "")
    strFormat = GetSetting(C_TITLE, "Fusen", "Format", "yyyy.mm.dd hh:mm:ss")
    strFusenDate = GetSetting(C_TITLE, "Fusen", "FusenDate", C_FUSEN_DATE_SYSTEM)
    
    strFont = GetSetting(C_TITLE, "Fusen", "Font", "Meiryo UI")
    strSize = GetSetting(C_TITLE, "Fusen", "Size", "9")
    
    varHorizontalAnchor = GetSetting(C_TITLE, "Fusen", "HorizontalAnchor", 0)
    varVerticalAnchor = GetSetting(C_TITLE, "Fusen", "VerticalAnchor", 0)
    
    varAutoSize = GetSetting(C_TITLE, "Fusen", "AutoSize", False)
    varOverFlow = GetSetting(C_TITLE, "Fusen", "OverFlow", False)
    varWordWrap = GetSetting(C_TITLE, "Fusen", "WordWrap", True)

End Sub
'--------------------------------------------------------------
'　付箋貼り付け
'--------------------------------------------------------------
Sub pasteFusen(ByVal strId As String, ByVal Index As Long)

    Dim obj As Object
    
    If ActiveWorkbook Is Nothing Then
        MsgBox "アクティブなブックが見つかりません。", vbCritical, C_TITLE
        Exit Sub
    End If
    
    If ActiveWorkbook.MultiUserEditing Then
        MsgBox "共有中はシェイプを追加できません。", vbCritical, C_TITLE
        Exit Sub
    End If
    
    Select Case strId
        Case "fsGallery01"
            Set obj = New ShapePasteFusenSquare
        Case "fsGallery02"
            Set obj = New ShapePasteFusenMemo
        Case "fsGallery03"
            Set obj = New ShapePasteFusenCall
        Case "fsGallery04"
            Set obj = New ShapePasteFusenCircle
        Case "fsGallery05"
            Set obj = New ShapePasteFusenPin
        Case "fsGallery06"
            Set obj = New ShapePasteFusenCall2
    End Select

    obj.id = strId
    obj.No = Index

    obj.Run

    Set obj = Nothing

End Sub
'--------------------------------------------------------------
'　付箋貼り付け
'--------------------------------------------------------------
Sub pasteFusenOrg(ByVal strId As String, ByVal Index As Long)

    Dim r As Shape
    
    If ActiveWorkbook Is Nothing Then
        MsgBox "アクティブなブックが見つかりません。", vbCritical, C_TITLE
        Exit Sub
    End If
    
'    Application.ScreenUpdating = False
    
    On Error GoTo e
    
    Set r = ThisWorkbook.Worksheets(strId).Shapes("shpSquare" & Format(Index, "00"))

    r.Copy
    Call CopyClipboardSleep
 
10    ActiveSheet.Paste
    
    Dim strText As String
    Dim strTag As String
    Dim varPrint As Variant
    
    Dim strWidth  As String
    Dim strHeight  As String
    
    Dim strFormat As String
    Dim strUserDate  As String
    Dim strFusenDate As String
    
    Dim strFont  As String
    Dim strSize  As String
    
    Dim strHorizontalAnchor  As String
    Dim strVerticalAnchor  As String
    
    Dim varAutoSize  As Variant
    Dim varOverFlow As Variant
    Dim varWordWrap As Variant
    
    Call getSettingFusen(strText, strTag, varPrint, strWidth, strHeight, strFormat, strUserDate, strFusenDate, strFont, strSize, strHorizontalAnchor, strVerticalAnchor, varAutoSize, varOverFlow, varWordWrap)
    
    If strId <> "fsGallery05" Then
        Selection.ShapeRange.width = CDbl(strWidth) * 10 * C_RASIO
        Selection.ShapeRange.Height = CDbl(strHeight) * 10 * C_RASIO
    End If
    
    Selection.ShapeRange.AlternativeText = strTag
    
    Dim strDate As String
    
    strDate = getFormatDate(strFormat, strFusenDate, strUserDate)
    strText = Replace(strText, "$d", strDate)
    strText = Replace(strText, "$u", Application.UserName)
    
    Selection.ShapeRange.TextFrame2.TextRange.Font.Name = strFont
    Selection.ShapeRange.TextFrame2.TextRange.Font.NameComplexScript = strFont
    Selection.ShapeRange.TextFrame2.TextRange.Font.NameFarEast = strFont
    Selection.ShapeRange.TextFrame2.TextRange.Font.NameAscii = strFont
    Selection.ShapeRange.TextFrame2.TextRange.Font.NameOther = strFont

    
    Selection.ShapeRange.TextFrame2.TextRange.Font.size = CDbl(strSize)
    Selection.ShapeRange.TextFrame2.TextRange.Text = strText
    
    If strId <> "fsGallery05" Then
        Select Case strVerticalAnchor
            Case "0"
                Selection.ShapeRange.TextFrame2.VerticalAnchor = msoAnchorTop
            Case "1"
                Selection.ShapeRange.TextFrame2.VerticalAnchor = msoAnchorMiddle
            Case "2"
                Selection.ShapeRange.TextFrame2.VerticalAnchor = msoAnchorBottom
        End Select
            
        Select Case strHorizontalAnchor
            Case "0"
                Selection.ShapeRange.TextFrame2.TextRange.ParagraphFormat.Alignment = msoAlignLeft
            Case "1"
                Selection.ShapeRange.TextFrame2.TextRange.ParagraphFormat.Alignment = msoAlignCenter
            Case "2"
                Selection.ShapeRange.TextFrame2.TextRange.ParagraphFormat.Alignment = msoAlignRight
        End Select
    End If
    
    Selection.PrintObject = CBool(varPrint)
    
    If strId <> "fsGallery05" Then
        If CBool(varAutoSize) Then
            Selection.ShapeRange.TextFrame2.AutoSize = msoAutoSizeShapeToFitText
        Else
            Selection.ShapeRange.TextFrame2.AutoSize = msoAutoSizeNone
        End If
    End If
    
#If VBA7 Then
    If strId <> "fsGallery05" Then
        If CBool(varOverFlow) Then
            Selection.ShapeRange.TextFrame.HorizontalOverflow = xlOartHorizontalOverflowOverflow
            Selection.ShapeRange.TextFrame.VerticalOverflow = xlOartVerticalOverflowOverflow
        Else
            Selection.ShapeRange.TextFrame.HorizontalOverflow = xlOartHorizontalOverflowClip
            Selection.ShapeRange.TextFrame.VerticalOverflow = xlOartVerticalOverflowClip
        End If
    End If
#End If

    If strId <> "fsGallery05" Then
        Selection.ShapeRange.TextFrame2.WordWrap = CBool(varWordWrap)
    End If
    
    Exit Sub
e:
    If Erl = 10 Then
        Resume
    End If
    
End Sub

'--------------------------------------------------------------
'　日付書式設定
'--------------------------------------------------------------
Private Function getFormatDate(ByVal strFormat As String, _
                        ByVal strType As String, _
                        ByVal strUserDate As String)
    
    On Error Resume Next

    If Len(Trim(strFormat)) = 0 Then
        getFormatDate = ""
        Exit Function
    End If
    
    Select Case strType
        Case C_FUSEN_DATE_SYSTEM
            getFormatDate = Format(Now, strFormat)
            
        Case C_FUSEN_DATE_USER
            If IsDate(strUserDate) Then
                getFormatDate = Format(CDate(strUserDate), strFormat)
            Else
                getFormatDate = ""
            End If
    End Select

End Function
'--------------------------------------------------------------
'　イメージファイル作成
'--------------------------------------------------------------
Function getImageFusen(ByVal strId As String, ByVal Index As Long) As StdPicture
    
    On Error Resume Next
    
    Set getImageFusen = Nothing
    
    Dim r As Shape
    Set r = ThisWorkbook.Worksheets(strId).Shapes("shpSquare" & Format(Index, "00"))
    
    Set getImageFusen = CreatePictureFromClipboard(r)
    
End Function
'--------------------------------------------------------------
'　付箋貼り付けのショートカット用
'--------------------------------------------------------------
Sub pasteSquareW()

    Dim obj As ShapePasteFusenSquare
    
    Set obj = New ShapePasteFusenSquare
    
    obj.id = "fsGallery01"
    obj.No = 1
    
    obj.Run
    
    Set obj = Nothing

End Sub
Sub pasteSquareY()


    Dim obj As ShapePasteFusenSquare
    
    Set obj = New ShapePasteFusenSquare
    
    obj.id = "fsGallery01"
    obj.No = 2
    
    obj.Run
    
    Set obj = Nothing

End Sub
Sub pasteSquareP()
    Dim obj As ShapePasteFusenSquare
    
    Set obj = New ShapePasteFusenSquare
    
    obj.id = "fsGallery01"
    obj.No = 3
    obj.Run
    
    Set obj = Nothing

End Sub
Sub pasteSquareB()
    Dim obj As ShapePasteFusenSquare
    
    Set obj = New ShapePasteFusenSquare
    
    obj.id = "fsGallery01"
    obj.No = 4
    obj.Run
    
    Set obj = Nothing

End Sub
Sub pasteSquareG()
    Dim obj As ShapePasteFusenSquare
    
    Set obj = New ShapePasteFusenSquare
    
    obj.id = "fsGallery01"
    obj.No = 5
    obj.Run
    
    Set obj = Nothing

End Sub
Sub beforePasteSquare()
    Dim obj As ShapePasteFusenSquare
    
    Set obj = New ShapePasteFusenSquare
    
    obj.id = "fsGallery01"
    obj.No = Val(GetSetting(C_TITLE, "Fusen", obj.id, "2"))
    obj.Run
    
    Set obj = Nothing
End Sub
Sub pasteMemoW()
    Dim obj As ShapePasteFusenMemo
    
    Set obj = New ShapePasteFusenMemo
    
    obj.id = "fsGallery02"
    obj.No = 1
    obj.Run
    
    Set obj = Nothing

End Sub
Sub pasteMemoY()
    Dim obj As ShapePasteFusenMemo
    
    Set obj = New ShapePasteFusenMemo
    
    obj.id = "fsGallery02"
    obj.No = 2
    obj.Run
    
    Set obj = Nothing

End Sub
Sub pasteMemoP()
    Dim obj As ShapePasteFusenMemo
    
    Set obj = New ShapePasteFusenMemo
    
    obj.id = "fsGallery02"
    obj.No = 3
    obj.Run
    
    Set obj = Nothing

End Sub
Sub pasteMemoB()
    Dim obj As ShapePasteFusenMemo
    
    Set obj = New ShapePasteFusenMemo
    
    obj.id = "fsGallery02"
    obj.No = 4
    obj.Run
    
    Set obj = Nothing

End Sub
Sub pasteMemoG()
    Dim obj As ShapePasteFusenMemo
    
    Set obj = New ShapePasteFusenMemo
    
    obj.id = "fsGallery02"
    obj.No = 5
    obj.Run
    
    Set obj = Nothing

End Sub
Sub beforePasteMemo()
    Dim obj As ShapePasteFusenMemo
    
    Set obj = New ShapePasteFusenMemo
    
    obj.id = "fsGallery02"
    obj.No = Val(GetSetting(C_TITLE, "Fusen", obj.id, "2"))
    obj.Run
    
    Set obj = Nothing
End Sub
Sub pasteCallW()
    Dim obj As ShapePasteFusenCall
    
    Set obj = New ShapePasteFusenCall
    
    obj.id = "fsGallery03"
    obj.No = 1
    obj.Run
    
    Set obj = Nothing

End Sub
Sub pasteCallY()
    Dim obj As ShapePasteFusenCall
    
    Set obj = New ShapePasteFusenCall
    
    obj.id = "fsGallery03"
    obj.No = 2
    obj.Run
    
    Set obj = Nothing

End Sub
Sub pasteCallP()
    Dim obj As ShapePasteFusenCall
    
    Set obj = New ShapePasteFusenCall
    
    obj.id = "fsGallery03"
    obj.No = 3
    obj.Run
    
    Set obj = Nothing

End Sub
Sub pasteCallB()
    Dim obj As ShapePasteFusenCall
    
    Set obj = New ShapePasteFusenCall
    
    obj.id = "fsGallery03"
    obj.No = 4
    obj.Run
    
    Set obj = Nothing

End Sub
Sub pasteCallG()
    Dim obj As ShapePasteFusenCall
    
    Set obj = New ShapePasteFusenCall
    
    obj.id = "fsGallery03"
    obj.No = 5
    obj.Run
    
    Set obj = Nothing

End Sub
Sub beforePasteCall()
    Dim obj As ShapePasteFusenCall
    
    Set obj = New ShapePasteFusenCall
    
    obj.id = "fsGallery03"
    obj.No = Val(GetSetting(C_TITLE, "Fusen", obj.id, "2"))
    obj.Run
    
    Set obj = Nothing
End Sub
Sub pasteCircleW()
    Dim obj As ShapePasteFusenCircle
    
    Set obj = New ShapePasteFusenCircle
    
    obj.id = "fsGallery04"
    obj.No = 1
    obj.Run
    
    Set obj = Nothing

End Sub
Sub pasteCircleY()
    Dim obj As ShapePasteFusenCircle
    
    Set obj = New ShapePasteFusenCircle
    
    obj.id = "fsGallery04"
    obj.No = 2
    obj.Run
    
    Set obj = Nothing

End Sub
Sub pasteCircleP()
    Dim obj As ShapePasteFusenCircle
    
    Set obj = New ShapePasteFusenCircle
    
    obj.id = "fsGallery04"
    obj.No = 3
    obj.Run
    
    Set obj = Nothing

End Sub
Sub pasteCircleB()
    Dim obj As ShapePasteFusenCircle
    
    Set obj = New ShapePasteFusenCircle
    
    obj.id = "fsGallery04"
    obj.No = 4
    obj.Run
    
    Set obj = Nothing

End Sub
Sub pasteCircleG()
    Dim obj As ShapePasteFusenCircle
    
    Set obj = New ShapePasteFusenCircle
    
    obj.id = "fsGallery04"
    obj.No = 5
    obj.Run
    
    Set obj = Nothing

End Sub
Sub beforePasteCircle()
    Dim obj As ShapePasteFusenCircle
    
    Set obj = New ShapePasteFusenCircle
    
    obj.id = "fsGallery04"
    obj.No = Val(GetSetting(C_TITLE, "Fusen", obj.id, "2"))
    obj.Run
    
    Set obj = Nothing
End Sub
Sub pastePinW()
    Dim obj As ShapePasteFusenPin
    
    Set obj = New ShapePasteFusenPin
    
    obj.id = "fsGallery05"
    obj.No = 1
    obj.Run
    
    Set obj = Nothing

End Sub
Sub pastePinY()
    Dim obj As ShapePasteFusenPin
    
    Set obj = New ShapePasteFusenPin
    
    obj.id = "fsGallery05"
    obj.No = 2
    obj.Run
    
    Set obj = Nothing

End Sub
Sub pastePinP()
    Dim obj As ShapePasteFusenPin
    
    Set obj = New ShapePasteFusenPin
    
    obj.id = "fsGallery05"
    obj.No = 3
    obj.Run
    
    Set obj = Nothing

End Sub
Sub pastePinB()
    Dim obj As ShapePasteFusenPin
    
    Set obj = New ShapePasteFusenPin
    
    obj.id = "fsGallery05"
    obj.No = 4
    obj.Run
    
    Set obj = Nothing

End Sub
Sub pastePinG()
    Dim obj As ShapePasteFusenPin
    
    Set obj = New ShapePasteFusenPin
    
    obj.id = "fsGallery05"
    obj.No = 5
    obj.Run
    
    Set obj = Nothing

End Sub
Sub beforePastePin()
    Dim obj As ShapePasteFusenPin
    
    Set obj = New ShapePasteFusenPin
    
    obj.id = "fsGallery05"
    obj.No = Val(GetSetting(C_TITLE, "Fusen", obj.id, "2"))
    obj.Run
    
    Set obj = Nothing
End Sub
Sub pasteLineW()
    Dim obj As ShapePasteFusenCall2
    
    Set obj = New ShapePasteFusenCall2
    
    obj.id = "fsGallery06"
    obj.No = 1
    obj.Run
    
    Set obj = Nothing

End Sub
Sub pasteLineY()
    Dim obj As ShapePasteFusenCall2
    
    Set obj = New ShapePasteFusenCall2
    
    obj.id = "fsGallery06"
    obj.No = 2
    obj.Run
    
    Set obj = Nothing

End Sub
Sub pasteLineP()
    Dim obj As ShapePasteFusenCall2
    
    Set obj = New ShapePasteFusenCall2
    
    obj.id = "fsGallery06"
    obj.No = 3
    obj.Run
    
    Set obj = Nothing

End Sub
Sub pasteLineB()
    Dim obj As ShapePasteFusenCall2
    
    Set obj = New ShapePasteFusenCall2
    
    obj.id = "fsGallery06"
    obj.No = 4
    obj.Run
    
    Set obj = Nothing

End Sub
Sub pasteLineG()
    Dim obj As ShapePasteFusenCall2
    
    Set obj = New ShapePasteFusenCall2
    
    obj.id = "fsGallery06"
    obj.No = 5
    obj.Run
    
    Set obj = Nothing

End Sub
Sub beforePasteLine()
    Dim obj As ShapePasteFusenCall2
    
    Set obj = New ShapePasteFusenCall2
    
    obj.id = "fsGallery06"
    obj.No = Val(GetSetting(C_TITLE, "Fusen", obj.id, "2"))
    obj.Run
    
    Set obj = Nothing
End Sub
