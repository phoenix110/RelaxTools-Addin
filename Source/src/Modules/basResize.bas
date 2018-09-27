Attribute VB_Name = "basResize"
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

'Windows API宣言
#If VBA7 And Win64 Then
    Private Declare PtrSafe Function GetWindowLong Lib "user32" Alias "GetWindowLongPtrA" (ByVal hwnd As LongPtr, ByVal nIndex As Long) As LongPtr
    Private Declare PtrSafe Function SetWindowLong Lib "user32" Alias "SetWindowLongPtrA" (ByVal hwnd As LongPtr, ByVal nIndex As Long, ByVal dwNewLong As LongPtr) As LongPtr
    Private Declare PtrSafe Function GetActiveWindow Lib "user32" () As LongPtr
    Private Declare PtrSafe Function DrawMenuBar Lib "user32" (ByVal hwnd As LongPtr) As LongPtr
    Private Declare PtrSafe Function SetWindowPos Lib "user32" _
                                          (ByVal hwnd As LongPtr, _
                                           ByVal hWndInsertAfter As LongPtr, _
                                           ByVal X As Long, ByVal Y As Long, _
                                           ByVal cx As Long, ByVal cy As Long, _
                                           ByVal wFlags As Long) As Long
#Else
    Private Declare Function SetWindowPos Lib "user32" _
                                      (ByVal hwnd As Long, _
                                       ByVal hWndInsertAfter As Long, _
                                       ByVal X As Long, ByVal Y As Long, _
                                       ByVal cx As Long, ByVal cy As Long, _
                                       ByVal wFlags As Long) As Long
    Private Declare Function GetWindowLong Lib "user32" Alias "GetWindowLongA" (ByVal hwnd As Long, ByVal nIndex As Long) As Long
    Private Declare Function SetWindowLong Lib "user32" Alias "SetWindowLongA" (ByVal hwnd As Long, ByVal nIndex As Long, ByVal dwNewLong As Long) As Long
    Private Declare Function GetActiveWindow Lib "user32" () As Long
    Private Declare Function DrawMenuBar Lib "user32" (ByVal hwnd As Long) As Long
#End If

Private Const HWND_TOPMOST As Long = -1
Private Const SWP_NOSIZE As Long = &H1&
Private Const SWP_NOMOVE As Long = &H2&
Private Const GWL_STYLE As Long = (-16)
Private Const WS_THICKFRAME As Long = &H40000
Private Const WS_SYSMENU = &H80000      '最大化／最小化／消去ボタンなど全て
Private Const WS_MINIMIZEBOX = &H20000  '最小化ボタン
Private Const WS_MAXIMIZEBOX = &H10000  '最大化ボタン
'--------------------------------------------------------------
' フォームをリサイズ可能にするための設定
'--------------------------------------------------------------
Public Sub FormResize()
#If VBA7 And Win64 Then
    Dim Result As LongPtr
    Dim hwnd As LongPtr
    Dim Wnd_STYLE As LongPtr
#Else
    Dim Result As Long
    Dim hwnd As Long
    Dim Wnd_STYLE As Long
#End If
 
    hwnd = GetActiveWindow()
    Wnd_STYLE = GetWindowLong(hwnd, GWL_STYLE)
    Wnd_STYLE = (Wnd_STYLE Or WS_THICKFRAME Or &H30000) - WS_MINIMIZEBOX
 
    Result = SetWindowLong(hwnd, GWL_STYLE, Wnd_STYLE)
    Result = DrawMenuBar(hwnd)
    
End Sub
