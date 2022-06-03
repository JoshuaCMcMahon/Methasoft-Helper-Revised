CheckReleases()
{
  ; Download the latest release or prerelease information
  if(ini_file.Autoupdate = 2) ; if config file shows you want prereleases, then download that isntead
  {

    UrlDownloadToFile, https://github.com/JoshuaCMcMahon/Methasoft-Helper-Revised/releases.atom, prereleases.atom

    ; Read the date and information about the latest prerelease
    Loop, Read, prereleases.atom
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


  }
  else ; otherwise just download the main releases
  {
    UrlDownloadToFile, https://api.github.com/repos/JoshuaCMcMahon/Methasoft-Helper-Revised/releases/latest, latestRelease.json
    FileRead, latestReleaseJSON, latestRelease.json

    published_at_location := InStr(latestReleaseJSON, "published_at")
    published_at_starting := published_at_location + 15
    published_at_ending := InStr(latestReleaseJSON, Chr(34), 0, published_at_starting, 1)

    latestUpdate := SubStr(latestReleaseJSON, published_at_starting, published_at_ending - published_at_starting)

    RemoveCharacters := ["-", ":", "T", "Z"]
    for index, value in RemoveCharacters ; get rid of a bunch of different characters.
    {
      latestUpdate := StrReplace(latestUpdate, value)
    }

    zipball_url_location := InStr(latestReleaseJSON, "zipball_url")
    zipball_url_starting := zipball_url_location + 14
    zipball_url_ending := InStr(latestReleaseJSON, Chr(34), 0, zipball_url_starting, 1)

    URL := SubStr(latestReleaseJSON, zipball_url_starting, zipball_url_ending - zipball_url_starting)
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

  ; Determine if we need to update or not
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
    ErrorCountArray := UpdateHelper(URL) ; run the updater
    if(ErrorCountArray[1] != 0) ; if the updater returned an error...
    {
      currentVersion.Write("Error`n" ErrorCountArray[1] " Files/Folders couldn't be overwritten:`n" ErrorCountArray[2]) ; write that error to the currentVersion file.
    }
    else
    {
      currentVersion.Write(latestUpdate) ; otherwise write the newest date after the update completed.
      Run, https://joshuamcmahon.notion.site/Change-Log-3b7c260194d64a04aeab0c09b6204003
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
  FileRemoveDir, % A_ScriptDir "\Extracted", 1 ; Delete the Extracted folder if it already exists
  Unzip(A_ScriptDir "\Update.zip", A_ScriptDir "\Extracted") ; extract it to Update.zip
  FileDelete, % A_ScriptDir "\Update.zip" ; Delete the original zip file; don't need it anymore.
  Loop, Files, % A_ScriptDir "\Extracted\*", D ; iterate through all the folders in Extracted and rename to "Methasoft-Helper-Revised"; there should only be one folder.
  {
    FileMoveDir, % A_LoopFilePath, % A_LoopFileDir "\Methasoft-Helper-Revised", R ; This actually renames the folder.
  }



  ErrorCountArray := MoveFilesAndFolders(A_ScriptDir "\Extracted\Methasoft-Helper-Revised\", A_ScriptDir "\", 1) ; Move everything from Methasoft-Helper-Revised to the current script directory.


  FileRemoveDir, % A_ScriptDir "\Extracted", 1 ; Delete the extracted folder and all it's contents
  if(ErrorLevel)
  {
    ErrorCountArray[1] += 1
    ErrorCountArray[2] .= "Couldn't delete " A_ScriptDir "\Extracted.`n"
  }

  return ErrorCountArray

}



MoveFilesAndFolders(SourcePattern, DestinationFolder, DoOverwrite := false)
; Moves all files and folders matching SourcePattern into the folder named DestinationFolder and
; returns the number of files/folders that could not be moved. This function requires [v1.0.38+]
; because it uses FileMoveDir's mode 2.
{
  debugArray := [0, ""]
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
  debugArray[1] := ErrorLevel

  ; Now move all the folders:
  Loop, Files, %SourcePattern%\*, D
  {
    if(InStr(A_LoopFileAttrib, "D")) ; if the current item is a directory
    {
      FileMoveDir, %A_LoopFileFullPath%, %DestinationFolder%\%A_LoopFileName%, %DoOverwrite%
      debugArray[1] += ErrorLevel
    }

    if ErrorLevel  ; Report each problem folder by name.
    {
      debugArray[2] .= "Could not move " A_LoopFileFullPath " into " DestinationFolder ".`n"
    }
  }
  return debugArray
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
