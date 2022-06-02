CheckReleases()
{
  ; Download the latest release information
  UrlDownloadToFile, https://github.com/JoshuaCMcMahon/Methasoft-Helper-Revised/releases.atom, releases.atom

  ; Get the date and information about the latest release
  Loop, Read, releases.atom
  {
    if(A_Index = 1 AND InStr(A_LoopReadLine, "<?xml") = 0) ; check to make sure we have an xml file
    {
      msgbox, not valid XML
      Return
    }

    if(InStr(A_LoopReadLine, "<entry>"))
    {
      foundEntry := 1
    }

    if(InStr(A_LoopReadLine, "<updated>") AND foundEntry = 1)
    {
      latestUpdate := Trim(A_LoopReadLine) ; Get rid of any leading or trailing whitespace.

      latestUpdate := SubStr(latestUpdate, 10, 19)

      RemoveCharacters := ["-", ":", "T"]

      for index, value in RemoveCharacters ; get rid of a bunch of different characters.
      {
        latestUpdate := StrReplace(latestUpdate, value)
      }
      ; msgbox, % latestUpdate
      ; FormatTime, latestUpdate, % latestUpdate, yyyy MM dd - hh mm ss
    }
    linkposition := InStr(A_LoopReadLine, " href=")
    if(linkposition AND foundEntry)
    {
      URL := SubStr(A_LoopReadLine, linkposition + 7)
      URL := Trim(URL)
      URL := StrReplace(URL, """/>")

      replacements := {"/releases/": "/archive/refs/", "/tag/": "/tags/"}
      for key, value in replacements
      {
        URL := StrReplace(URL, key, value)
      }

      URL .= ".zip"
      Break
    }
  }

  ; Get currently installed version information
  currentVersion_Exists := FileExist("currentVersion") ; Check to see if currentVersion exists.
  if(currentVersion_Exists != "") ; if it does exist, do the following.
  {
    currentVersion := FileOpen("currentVersion", "rw")
    timeInFile := currentVersion.Read()
    timeDifference := timeInFile
    EnvSub, timeDifference, % latestUpdate, seconds
  }
  else ; otherwise if currentVersion doesn't exist, do the following.
  {
    timeInFile := ""
  }

  if(InStr(timeInFile, "Error")) ; If currentVersion contains the word "Error"
  {
    msgbox, % "Methasoft Helper had issues updating; opening normally." ; Let the user know something went wrong, but otherwise open normally.
  }
  else if (timeDifference < 0 OR timeInFile = "") ; if helper needs updating, do the following.
  {
    if(ini_file.Autoupdate) ; if the user allows autoupdate based on the config file, run it.
    {
      Gosub PrepareUpdate
    }
    else ; if the user doesn't allow autoupdate based on the config file,
    {
      ; Hide the window so the user can see the msgbox.
      Gui, Splash:Hide
      msgbox, 4, Update Avaliable, % "There is an update for Methasoft Helper, would you like to install it?"
      Gui, Splash:Show
      IfMsgbox Yes
      {
        Gosub PrepareUpdate
      }
      else
      {
        ; Don't update, just keep swimming.
      }
    }

  }
  else
  {
    ; msgbox, no new updates
  }

  Return

  PrepareUpdate:
  {
    FileDelete, % "currentVersion" ; clear out the old version of the file.
    currentVersion := FileOpen("currentVersion", "rw") ; create a new version of the file.
    results := UpdateHelper(URL) ; run the updater
    if(results = "Error") ; if the updater returned an error...
    {
      currentVersion.Write(results) ; write that error to the currentVersion file.
    }
    else
    {
      currentVersion.Write(latestUpdate) ; otherwise write the newest date after the update completed.
    }
    Reload
  } Return
}

UpdateHelper(URL)
{

  ; Gui, Splash:New, HwndSplashWindow
  ; Gui, +AlwaysOnTop -SysMenu +Owner -Caption  ; +Owner avoids a taskbar button.
  ; Gui, Font, s24
  GuiControl,, SplashText, % "Updating the Helper..."
  ; Gui, Add, Text,, % ""
  ; Gui, Font
  ; Gui, Splash:Show, NoActivate Center, Updater  ; NoActivate avoids deactivating the currently active window.

  ; Process, Exist, % "Methasoft Helper Login"
  ; HelperPID := ErrorLevel
  ; msgbox, % "About to close Methasoft helper with pid of " HelperPID
  ; Process, Close, % HelperPID

  UrlDownloadToFile, % URL, Update.zip ; Download the latest update from GitHub
  Unzip(A_ScriptDir "\Update.zip", A_ScriptDir "\Extracted") ; extract it to Update.zip
  FileDelete, % A_ScriptDir "\Update.zip" ; Delete the original zip file; don't need it anymore.
  Loop, Files, % A_ScriptDir "\Extracted\*", D ; iterate through all the folders in Extracted and rename to "Methasoft-Helper-Revised"; there should only be one folder.
  {
    FileMoveDir, % A_LoopFilePath, % A_LoopFileDir "\Methasoft-Helper-Revised", R ; This actually renames the folder.
  }



  ErrorCount := MoveFilesAndFolders(A_ScriptDir "\Extracted\Methasoft-Helper-Revised\", A_ScriptDir "\", 1) ; Move everything from Methasoft-Helper-Revised to the current script directory.
  if (ErrorCount != 0)
  {
    results := "Error"
    MsgBox %ErrorCount% files/folders could not be moved.
  }
  else
  {
    results := "Success"
  }

  FileRemoveDir, % A_ScriptDir "\Extracted", 1 ; Delete the extracted folder and all it's contents
  if(ErrorLevel)
  {
    msgbox, couldn't delete
  }

  return results

}



MoveFilesAndFolders(SourcePattern, DestinationFolder, DoOverwrite := false)
; Moves all files and folders matching SourcePattern into the folder named DestinationFolder and
; returns the number of files/folders that could not be moved. This function requires [v1.0.38+]
; because it uses FileMoveDir's mode 2.
{

  if (DoOverwrite = 1)
  {
    DoOverwrite := 2  ; See FileMoveDir for description of mode 2 vs. 1.
    OverwriteFiles := 1 ; Needed to fix the overwrite Files command; 2 is not considered a valid True statement
  }
  else
  {
    OverwriteFiles := 0
  }

  ; First move all the files (but not the folders):
  FileMove, %SourcePattern%, %DestinationFolder%, % OverwriteFiles
  ErrorCount := ErrorLevel

  ; Now move all the folders:
  Loop, Files, %SourcePattern%\*, D
  {
    if(InStr(A_LoopFileAttrib, "D")) ; if the current item is a directory
    {
      FileMoveDir, %A_LoopFileFullPath%, %DestinationFolder%\%A_LoopFileName%, %DoOverwrite%
      ErrorCount += ErrorLevel
    }

    if ErrorLevel  ; Report each problem folder by name.
    {
      MsgBox Could not move %A_LoopFileFullPath% into %DestinationFolder%.
    }
  }
  return ErrorCount
}




Unzip(ZippedFile, DestinationLocation)
{
    fso := ComObjCreate("Scripting.FileSystemObject")
    If Not fso.FolderExists(DestinationLocation)  ;http://www.autohotkey.com/forum/viewtopic.php?p=402574
       fso.CreateFolder(DestinationLocation)
    psh  := ComObjCreate("Shell.Application")
    zippedItems := psh.Namespace( ZippedFile ).items().count
    psh.Namespace( DestinationLocation ).CopyHere( psh.Namespace( ZippedFile ).items, 4|16 )
    Loop
    {
        sleep 50
        unzippedItems := psh.Namespace( DestinationLocation ).items().count
        ; ToolTip Unzipping in progress..
        IfEqual,zippedItems,%unzippedItems%
            break
    }
    ; ToolTip
}
