'-------------------------------------------------------------------------------
' �����u�b�N���Q�Ɨp�ɊJ���X�N���v�g
' 
' rlxAliasOpen.vbs
' 
' Copyright (c) 2018 Y.Watanabe
' 
' This software is released under the MIT License.
' http://opensource.org/licenses/mit-license.php
'-------------------------------------------------------------------------------
' ����m�F : Windows 7 + Excel 2016 / Windows 10 + Excel 2016
' �R�}���h���C��
'   /install   �F�C���X�g�[�����܂��B
'   /uninstall �F�A���C���X�g�[�����܂��B
'-------------------------------------------------------------------------------
' �C������
'   1.1.0 �����u�b�N����ׂĔ�r(&F)�R�}���h��ǉ��B
'   1.0.0 �V�K�쐬
'-------------------------------------------------------------------------------
Option Explicit

    Const C_TITLE = "RelaxTools-Addin"
    Const C_REF = "�i�Q�Ɨp�j"
    Const C_COMPARE = "/C"
    Const C_INSTALL = "/RUNINSTALL"
    Const C_UNINSTALL = "/RUNUNINSTALL"

    Dim strActBook
    Dim strTmpBook
    Dim strFile
    Dim FS, v, varExt, k

    Set FS = CreateObject("Scripting.FileSystemObject")

    If WScript.Arguments.Count > 0 Then

        v = WScript.Arguments(0)

        Select Case UCase(v)
            Case "/INSTALL"
                '�������g���Ǘ��Ҍ����Ŏ��s
                With CreateObject("Shell.Application")
                    .ShellExecute WScript.FullName, """" & WScript.ScriptFullName & """ " & C_INSTALL, "", "runas"
                End With
                WScript.Quit

            Case "/UNINSTALL"
                '�������g���Ǘ��Ҍ����Ŏ��s
                With CreateObject("Shell.Application")
                    .ShellExecute WScript.FullName, """" & WScript.ScriptFullName & """ " & C_UNINSTALL, "", "runas"
                End With
                WScript.Quit

            Case C_INSTALL
                On Error Resume Next
                Err.Clear
                With WScript.CreateObject("WScript.Shell")
                    '�u�b�N����ύX���ĊJ��
                    varExt = Array("Excel.Sheet.8", "Excel.Sheet.12", "Excel.SheetMacroEnabled.12")
                    For Each k In varExt
                       .RegWrite "HKCR\" & k & "\shell\rlxAliasOpen\","�����u�b�N���Q�Ɨp�ɊJ��(&B)", "REG_SZ"
                       .RegWrite "HKCR\" & k & "\shell\rlxAliasOpen\command\","""" & FS.GetSpecialFolder(1) & "\wscript.exe"" """ & .SpecialFolders("AppData") & "\RelaxTools-Addin\rlxAliasOpen.vbs"" ""%1""", "REG_SZ"
                       .RegWrite "HKCR\" & k & "\shell\rlxAliasOpenDiff\","�����u�b�N����ׂĔ�r(&F)", "REG_SZ"
                       .RegWrite "HKCR\" & k & "\shell\rlxAliasOpenDiff\command\","""" & FS.GetSpecialFolder(1) & "\wscript.exe"" """ & .SpecialFolders("AppData") & "\RelaxTools-Addin\rlxAliasOpen.vbs"" """ & C_COMPARE & """ ""%1""", "REG_SZ"
                    Next            
                End With
                If Err.Number = 0 Then
                    MsgBox "���W�X�g�����X�V���܂����B", vbInformation + vbOkOnly, C_TITLE
                Else
                    MsgBox "�G���[���������܂����B", vbCritical + vbOkOnly, C_TITLE
                End IF

            Case C_UNINSTALL
                On Error Resume Next
                Err.Clear
                With WScript.CreateObject("WScript.Shell")
                    '�u�b�N����ύX���ĊJ��
                    varExt = Array("Excel.Sheet.8", "Excel.Sheet.12", "Excel.SheetMacroEnabled.12")
                    For Each k In varExt
                       .RegDelete "HKCR\" & k & "\shell\rlxAliasOpen\command\"
                       .RegDelete "HKCR\" & k & "\shell\rlxAliasOpen\"
                       .RegDelete "HKCR\" & k & "\shell\rlxAliasOpenDiff\command\"
                       .RegDelete "HKCR\" & k & "\shell\rlxAliasOpenDiff\"
                    Next            
                End With
                'MsgBox "�A���C���X�g�[�����܂����B", vbInformation + vbOkOnly, C_TITLE

            Case C_COMPARE
                '��r���[�h
                If WScript.Arguments.Count > 1 Then
                    v = WScript.Arguments(1)
                    ExecExcel v, True
                Else
                    MsgBox "�t�@�C�������ݒ肳��Ă��܂���B", vbInformation + vbOkOnly, C_TITLE 
                End If

            Case Else
                '�ʏ탂�[�h
                ExecExcel v, False
        End Select

    End If
    
    Set FS = Nothing

'--------------------------------------------------------------
'�@�����u�b�N���J��
'--------------------------------------------------------------
Sub ExecExcel(v, c)

    Dim XL, WB, W2, blnFind

    strActBook = v
    strTmpBook = rlxGetTempFolder() & C_REF & FS.GetFileName(v)
    FS.CopyFile strActBook, strTmpBook

    Err.Clear
    On Error Resume Next
    Set XL = GetObject(,"Excel.Application")
    If Err.Number = 0 Then

        Set WB = XL.Workbooks.Open(strTmpBook,,1)
        
        '��r���[�h
        If c Then
            blnFind = False
            For Each W2 In XL.Workbooks
                If W2.Name = FS.GetFileName(v) Then
                    blnFind = True
                    Exit For
                End If
            Next
            If blnFind Then
                '��r�̂��߂`�P�ɂ���
                setAllA1 WB
                setAllA1 W2

                '��r
                WB.Activate
                WB.Application.Windows.CompareSideBySideWith FS.GetFileName(v)
                W2.Activate
            Else
                MsgBox "��r��̃u�b�N��������܂���B", vbInformation + vbOkOnly, C_TITLE 
            End If

        Else
            WB.Activate
        End If
    Else
        'MsgBox "Excel���N�����Ă��Ȃ��Ǝ��s�ł��܂���B", vbInformation + vbOkOnly, C_TITLE 
        With WScript.CreateObject("WScript.Shell")
            .Run strTmpBook, 1, True
        End With
    End If

End Sub
'--------------------------------------------------------------
'�@�e���|�����t�H���_�擾
'--------------------------------------------------------------
Public Function rlxGetTempFolder() 

    On Error Resume Next
    
    Dim strFolder
    
    rlxGetTempFolder = ""
    
    With FS
    
        strFolder = rlxGetAppDataFolder & "Temp"
        
        If .FolderExists(strFolder) Then
        Else
            .createFolder strFolder
        End If
        
        rlxGetTempFolder = .BuildPath(strFolder, "\")
        
    End With
    

End Function

'--------------------------------------------------------------
'�@�A�v���P�[�V�����t�H���_�擾
'--------------------------------------------------------------
Function rlxGetAppDataFolder() 

    On Error Resume Next
    
    Dim strFolder
    
    rlxGetAppDataFolder = ""
    
    With FS
    
        strFolder = .BuildPath(CreateObject("Wscript.Shell").SpecialFolders("AppData"), C_TITLE)
        
        If .FolderExists(strFolder) Then
        Else
            .createFolder strFolder
        End If
        
        rlxGetAppDataFolder = .BuildPath(strFolder, "\")
        
    End With

End Function
'--------------------------------------------------------------
'�@���ׂẴV�[�g�̑I���ʒu���`�P�ɃZ�b�g
'--------------------------------------------------------------
Sub setAllA1(WB)

    On Error Resume Next

    WB.Application.ScreenUpdating = False

    Dim WS
    Dim lngPercent
 
    lngPercent = 100
  
    For Each WS In WB.Worksheets
        If WS.visible = -1 Then
            WS.Activate
            WS.Range("A1").Activate
            WB.Windows(1).ScrollRow = 1
            WB.Windows(1).ScrollColumn = 1
            
            WB.Windows(1).Zoom = lngPercent

        End If
    Next

    For Each WS In WB.Worksheets
        If WS.visible = -1 Then
            WS.Select
            Exit For
        End If
    Next
    
    WB.Application.ScreenUpdating = True
    
End Sub

