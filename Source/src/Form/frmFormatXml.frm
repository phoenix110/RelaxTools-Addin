VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} frmFormatXml 
   Caption         =   "美しすぎるXML整形"
   ClientHeight    =   2190
   ClientLeft      =   45
   ClientTop       =   435
   ClientWidth     =   3120
   OleObjectBlob   =   "frmFormatXml.frx":0000
   StartUpPosition =   1  'オーナー フォームの中央
End
Attribute VB_Name = "frmFormatXml"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
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

Private Sub cmdCancel_Click()
    Unload Me
End Sub

Private Sub cmdOk_Click()

    If Len(Trim(txtSpace.Text)) = 0 Or Not rlxIsNumber(txtSpace.Text) Then
        Call MsgBox("SPACEの数は数字を入力してください。", vbOKOnly + vbExclamation, C_TITLE)
        Exit Sub
    End If
    
    SaveSetting C_TITLE, "XML", "Tab", optTab.Value
    SaveSetting C_TITLE, "XML", "Seed", txtSpace.Text
    
    Unload Me
    
End Sub


Private Sub optSpace_Change()
    txtSpace.enabled = optSpace.Value
End Sub

Private Sub optTab_Change()
    txtSpace.enabled = optSpace.Value
End Sub


Private Sub UserForm_Initialize()

    If CBool(GetSetting(C_TITLE, "XML", "Tab", False)) Then
        optTab.Value = True
        optSpace.Value = False
    Else
        optTab.Value = False
        optSpace.Value = True
    End If

    txtSpace.Text = GetSetting(C_TITLE, "XML", "Seed", 2)
    
End Sub
