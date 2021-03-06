#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Event  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance Force

DetectHiddenWindows, On ; Fixes the issue where Methasoft's PID shows as closed when it's loading a new window (such as logging into Methasoft).
Thread, Interrupt, 100 ; Allows SetTimer threads to be inturruptable so that they all run concurrently. Using Critical makes them uninturruptable, such as for an imagesearch (still needs to be tested).

; -------------------------------
; Setup Globals
; -------------------------------

Process, Exist
Global HelperPID := ErrorLevel
Global ActiveSessions := {}
Global console := ""
Global critical_message := ""
Global ini_file := {}

; SetTimer, ControlName, 100




; -------------------------------
; Main Program
; -------------------------------
#Include Updater.ahk

Load_INI()
Gosub MainGUI
Global debug := new DebugClass("Helper Debug", "+Owner" HelperHandle " +AlwaysOnTop")
Global controls := new Methasoft_Controls()
Return

; -------------------------------
; Include Scripts
; -------------------------------

#Include Class Debugging.ahk
#Include csv.ahk
#Include Helper Gui.ahk
#Include Class Timer.ahk
#Include Class ActiveSession.ahk
#Include Class Control Database.ahk


ControlName()
{
  static message := ""
  static lastClassname := ""

  Process, Wait, Methasoft.Client.exe
  MethasoftPID := ErrorLevel
  WinGetClass, MethasoftClass, % "ahk_pid" MethasoftPID

  if(MethasoftClass != lastClassname)
  {
    message .= MethasoftClass "`n"
    lastClassname := MethasoftClass
  }

  Tooltip, % message

}

Stats()
{
  list := ""
  for key, value in ActiveSession.Sessions
  {
    list .= key ", " value "`n"
  }
  Tooltip, % list
}

Load_INI()
{
  inifile := "Helper.ini"

  ; IniRead, OutputVar, Filename, Section, Key, Default value if undefined

  ; Read the ini file, then write the same value back to it. This will create any keys that don't already exist without overwriting the user's preferences.
  IniRead, Username, % inifile, User, Username, %A_Space%
  IniWrite, % Username, % inifile, User, Username
  ini_file.Username := Username

  IniRead, Password, % inifile, User, Password, %A_Space%
  IniWrite, % Password, % inifile, User, Password
  ini_file.Password := Password

  IniRead, Autoadvance, % inifile, Helper Preferences, Autoadvance, 1
  IniWrite, % Autoadvance, % inifile, Helper Preferences, Autoadvance
  ini_file.Autoadvance := Autoadvance

  IniRead, Autoupdate, % inifile, Helper Preferences, Autoupdate, 1
  IniWrite, % Autoupdate, % inifile, Helper Preferences, Autoupdate
  ini_file.Autoupdate := Autoupdate

  IniRead, AutocloseNightlyProcesses, % inifile, Methasoft Preferences, AutocloseNightlyProcesses, 1
  IniWrite, % AutocloseNightlyProcesses, % inifile, Methasoft Preferences, AutocloseNightlyProcesses
  ini_file.AutocloseNightlyProcesses := AutocloseNightlyProcesses
}









Login_Button()
{
  Global Clinic_Dropdown_HWND

  GuiControlGet, Clinic_Dropdown
  ; Clinic_Dropdown_Array := [Clinic_Dropdown]
  ActiveSession.NewSession([Clinic_Dropdown])
  GuiControlGet, Autoadvance_Checkbox

  if(Autoadvance_Checkbox)
  {
    ControlSend,, {Down}, % "ahk_id " Clinic_Dropdown_HWND
  }
}


OpenCheckedClinics()
{
  Gui, Main:Default
  Gui, ListView, Filter_Listview
  clinic_array := []

  RowNumber := 0  ; This causes the first loop iteration to start the search at the top of the list.
  Loop
  {
    RowNumber := LV_GetNext(RowNumber, "Checked")  ; Resume the search at the row after that found by the previous iteration.
    if not RowNumber  ; The above returned zero, so there are no more selected rows.
        break
    LV_GetText(line_text, RowNumber)
    clinic_array.push(line_text)
  }

  ActiveSession.NewSession(clinic_array)

}

ShowActive_Button()
{
  TV_GetText(clinicName, TV_GetSelection()) ; Get the selected clinic's name
  ActiveSession.Sessions[clinicName].Activate() ; Activate the selected Methasoft Window
}

ListviewEvent()
{
  debug.print(, "ListviewEvent() - A_GuiControl: " A_GuiControl ", A_GuiEvent: " A_GuiEvent ", A_EventInfo: " A_EventInfo ".")

  ; ctrl+A - select all records in the listview
  if(A_GuiEvent = "K" AND A_EventInfo = 65 AND GetKeyState("LControl", "P"))
  {
    Gui, Listview, % A_GuiControl
    LV_Modify(0, "Select")
  }

  ; Ctrl+C - Check Selected Records
  else if(A_GuiEvent = "K" AND A_EventInfo = 67 AND GetKeyState("LControl", "P"))
  {
    Gui, Listview, % A_GuiControl
    RowNumber := 0  ; This causes the first loop iteration to start the search at the top of the list.
    Loop
    {
        RowNumber := LV_GetNext(RowNumber)  ; Resume the search at the row after that found by the previous iteration.
        if not RowNumber  ; The above returned zero, so there are no more selected rows.
            break
        LV_Modify(RowNumber, "Check")
    }
  }

  ; Ctrl+U - Unselect selected records
  else if(A_GuiEvent = "K" AND A_EventInfo = 85)
  {
    RowNumber := 0  ; This causes the first loop iteration to start the search at the top of the list.
    Loop
    {
        RowNumber := LV_GetNext(RowNumber)  ; Resume the search at the row after that found by the previous iteration.
        if not RowNumber  ; The above returned zero, so there are no more selected rows.
            break
        LV_Modify(RowNumber, "-Check")
    }
  }

  ; Doubleclick - different depending on if the user doubleclicks on a record or in the listview but off a record.
  else if(A_GuiEvent = "DoubleClick")
  {
    Gui, Listview, % A_GuiControl
    if(LV_GetNext() != 0 AND A_GuiControl != "Filter_Listview") ; if it is not zero, then the user double clicked on a specific item. Don't enable on the main clinic filters listview, it's not good design
    {
      LV_Modify(0, "-Check")
      LV_Modify(LV_GetNext(), "Check")
    }
    else
    {
      LV_Modify(LV_GetNext(), "Check") ; the user clicked in the listview but not on a specific item; check all items in listview
    }
  }

  ; Spacebar - toggle selected records
  else if(A_GuiEvent = "K" AND A_EventInfo = 32)
  {
    Gui, Listview, % A_GuiControl
    RowNumber := 0  ; This causes the first loop iteration to start the search at the top of the list.
    FocusedRow := LV_GetNext(RowNumber, "Focused")

    Loop
    {
        RowNumber := LV_GetNext(RowNumber)  ; Resume the search at the row after that found by the previous iteration.

        if not RowNumber  ; The above returned zero, so there are no more selected rows.
        {
          break
        }
        ; msgbox, % "Rownumber: " RowNumber "`nNext Checked: " LV_GetNext(RowNumber, "Checked")
        if(rownumber != FocusedRow)
        {
          if(LV_GetNext(RowNumber-1, "Checked") = RowNumber)
          {
            LV_Modify(RowNumber, "-Check")
          }
          else
          {
            LV_Modify(RowNumber, "Check")
          }
        }
    }
  }
}

ActiveSession_Event()
{
  debug.print(, A_Gui ", " A_GuiControl ", " A_GuiEvent ", " A_EventInfo)
  Critical, On
  if(A_GuiControl = "ActiveSessions_Treeview" AND A_GuiEvent = "DoubleClick") ; If the user doubleclicks on one of the active sessions, activate that Methasoft window
  {
    TV_GetText(clinicName, A_EventInfo)
    debug.print(, "DoubleClicked on " clinicName " in the active sessions listview.")
    DetectHiddenWindows, Off
    WinActivate, % "ahk_pid" ActiveSession.Sessions[clinicName].PID
    DetectHiddenWindows, On
  }
  else if(A_GuiControl = "ActiveSessions_Treeview" AND A_GuiEvent = "S")
  {
    for key, object in ActiveSession.Sessions
    {
      TV_Modify(object.ID, "-Check")
    }
    TV_Modify(A_EventInfo, "Check")
  }

}

MainGuiContextMenu()
{
  debug.print("", "A_GuiControl: " A_GuiControl ", A_EventInfo: " A_EventInfo ", A_GuiX & A_GuiY: " A_GuiX ", " A_GuiY ", A_GuiEvent: " A_GuiEvent)

  if(A_GuiControl = "ActiveSessions_Treeview") ; the user right clicked in the active sessions listview.
  {
    Critical, On ; Make this thread critical
    if(A_EventInfo != 0) ; the user clicked on a specfic item
    {
      TV_GetText(clinicName, A_EventInfo)
      ; Binds a function to a variable so it can be added to the Menu
      MakeActive := ActiveSession.Sessions[clinicName].BindFunction("Activate")
      CloseSession := ActiveSession.Sessions[clinicName].BindFunction("EndSession")

      ; Make the Top Level Menu
      Menu, ActiveSessions_MenuItem, Add, Show Window, % MakeActive
      Menu, ActiveSessions_MenuItem, Icon, Show Window, Icons\icons8-application-window-96.ico

      ; Add a Submenu for closing sessions
      ; Menu, ActiveSessions_MenuItem_ConfirmClose, Add, Confirm Close Session, % CloseSession
      ; Menu, ActiveSessions_MenuItem_ConfirmClose, Icon, Confirm Close Session, Icons\icons8-close-window-48.ico
      ; Menu, ActiveSessions_Menu_ConfirmClose, Add, Close Session, % CloseSession

      ; Connect the submenu(s) to the main menus
      Menu, ActiveSessions_MenuItem, Add, Close Session, % CloseSession
      Menu, ActiveSessions_MenuItem, Icon, Close Session, Icons\icons8-close-window-48.ico
      ; Show the menu
      Menu, ActiveSessions_MenuItem, Show
    }
    else if(TV_GetCount()) ; the user didn't click on an item but still clicked in the ActiveSession treeview
    {
      ; Binds a function to a variable so it can be added to the Menu
      CloseAllSessions := Func("ActiveSession.EndSession").Bind(1)
      totalClinics := TV_GetCount()




      Menu, ActiveSessions_Menu_ConfirmCloseAll, Add, Confirm Close All Session(s), % CloseAllSessions
      Menu, ActiveSessions_Menu_ConfirmCloseAll, Icon, Confirm Close All Session(s), Icons\icons8-close-window-48.ico

      Menu, ActiveSessions_Menu, Add, Close All Sessions, :ActiveSessions_Menu_ConfirmCloseAll

      Menu, ActiveSessions_Menu, Show
    }
  }
}

Filters:
{
  CSV_Load("Databases.csv", "Filter_List")

  Array_Legacy := []
  Array_Type := []
  Array_Zone := []
  Array_Region := []
  Array_State := []
  Array_Version := []

  Loop, % CSV_TotalRows("Filter_List")
  {
    if(A_Index != 1) ; Skip the header
    {

      Gui, Main:Default
      Gui, ListView, Filter_Listview
      LV_Add("Check", CSV_ReadCell("Filter_List", A_Index, 1), CSV_ReadCell("Filter_List", A_Index, 4), CSV_ReadCell("Filter_List", A_Index, 5), CSV_ReadCell("Filter_List", A_Index, 6), CSV_ReadCell("Filter_List", A_Index, 7), CSV_ReadCell("Filter_List", A_Index, 8), CSV_ReadCell("Filter_List", A_Index, 9))
      A_Index_Outer := A_Index

      Loop, % CSV_TotalCols("Filter_List") - 1 ; Loop through all columns excluding the first one.
      {
        Cell_value := CSV_ReadCell("Filter_List", A_Index_Outer, A_Index+3)

        Switch A_Index
        {
        Case 1:
          Array_Legacy := GetUniqueList(Cell_value, Array_Legacy)
        Case 2:
          Array_Type := GetUniqueList(Cell_value, Array_Type)
        Case 3:
          Array_Zone := GetUniqueList(Cell_value, Array_Zone)
        Case 4:
          Array_Region := GetUniqueList(Cell_value, Array_Region)
        Case 5:
          Array_State := GetUniqueList(Cell_value, Array_State)
        Case 6:
          Array_Version := GetUniqueList(Cell_value, Array_Version)
        }
      }
    }
  }



  AddArraytoListview(Array_Legacy, "Filters_LegacyM2M_Listview")
  AddArraytoListview(Array_Type, "Filters_Type_Listview")
  AddArraytoListview(Array_Zone, "Filters_Zone_Listview")
  AddArraytoListview(Array_Region, "Filters_Region_Listview")
  AddArraytoListview(Array_State, "Filters_State_Listview")
  AddArraytoListview(Array_Version, "Filters_Version_Listview")

  Gui, ListView, Filter_Listview
  LV_ModifyCol() ; Fit to width of data.

  Apply()

} Return

AddArraytoListview(array, listview)
{
  Gui, ListView, % listview
  for each, value in array
  {
    LV_Add("Check", value)
  }
  LV_ModifyCol(1, "Sort Auto")
}

GetUniqueList(input, array)
{
  for each, value in array ; iterate through the array
  {
    if(value = input) ; if the input is already in the array
    {
      return array ; return the array
    }
  }
  array.push(input) ; if the whole array was searched and there was no matching value, add it to the array
  return array
}












ApplyFilters()
{
  ; Get the text from each filter listview and add it to an array.
  GuiControl, Disable, Filter_Listview
  GuiControl, ChooseString, Filters_Tab, Clinic Filters
  Legacy_Array := GetCheckedListviewArray("Filters_LegacyM2M_Listview")
  Type_Array := GetCheckedListviewArray("Filters_Type_Listview")
  Version_Array := GetCheckedListviewArray("Filters_Version_Listview")
  Zone_Array := GetCheckedListviewArray("Filters_Zone_Listview")
  Region_Array := GetCheckedListviewArray("Filters_Region_Listview")
  State_Array := GetCheckedListviewArray("Filters_State_Listview")

  Gui, Main:Default
  Gui, Listview, Filter_Listview
  Loop, % LV_GetCount()
  {
    A_Index_Outer := A_Index
    currentLineArray := []

    Loop, 6
    {
      LV_GetText(text, A_Index_Outer, A_Index+1)
      currentLineArray.push(text)
    }

    if(ArrayContains(currentLineArray[1],Legacy_Array) AND ArrayContains(currentLineArray[2], Type_Array) AND ArrayContains(currentLineArray[3], Zone_Array) AND ArrayContains(currentLineArray[4], Region_Array) AND ArrayContains(currentLineArray[5], State_Array) AND ArrayContains(currentLineArray[6], Version_Array))
    {
      ; Check the record
      LV_Modify(A_Index, "Check")
    }
    else
    {
      ; Uncheck the record
      LV_Modify(A_Index, "-Check")
    }
  }
  GuiControl, Enable, Filter_Listview
  Apply()
}

ArrayContains(value, array)
{
  for each, item in array
  {
    if(item = value)
    {
      return 1
    }
  }
  return 0
}

GetCheckedListviewArray(Listview_Name)
{
  array := []
  RowNumber := 0  ; This causes the first loop iteration to start the search at the top of the list.
  Gui, Main:Default
  Gui, Listview, % Listview_Name
  Loop
  {
      RowNumber := LV_GetNext(RowNumber, "Checked")  ; Resume the search at the row after that found by the previous iteration.
      if not RowNumber  ; The above returned zero, so there are no more selected rows.
          break
      LV_GetText(Text, RowNumber)
      array.push(Text)
  }
  return array
}






Apply()
{
  Gui, Main:Default
  Gui, ListView, Filter_Listview
  RowNumber := 0  ; This causes the first loop iteration to start the search at the top of the list.
  dropdown_values := ""
  Loop
  {
      RowNumber := LV_GetNext(RowNumber, "Checked")  ; Resume the search at the row after that found by the previous iteration.
      if not RowNumber  ; The above returned zero, so there are no more selected rows.
        break
      LV_GetText(Text, RowNumber, 1)
      dropdown_values .= Text "|"
      ; ToolTip, % RowNumber
      count := A_Index
  }

  dropdown_values := "|" . StrReplace(dropdown_values, "|", "||",, 1) ; Replace the first bar character with two bars to make the list select the first item.
  GuiControl,, Clinic_Dropdown, % dropdown_values
  ; ToolTip, % "Loading Bar Data`nCurrent Number: " 0 "`nCurrent Total: " count, 0, 0, 2
  GuiControl, % "+Range0-" count, Clinic_Progress, 1
  Clinic_Progress()
  SB_SetText("Filters applied!")
}

Hide:
{
  WinGetPos, HelperX, HelperY,,, ahk_id %HelperHandle%
  WinMove, ahk_id %HelperHandle%,, HelperX, HelperY , 300
} Return

Clinic_Progress()
{
  GuiControl, +AltSubmit, Clinic_Dropdown
  GuiControlGet, currentNumber,, Clinic_Dropdown
  GuiControl, -AltSubmit, Clinic_Dropdown
  ; ToolTip, % "Loading Bar Data`nCurrent Number: " currentNumber "`nCurrent Total: " count, 0, 0, 2
  GuiControl,, Clinic_Progress, % currentNumber

}

Preferences_Window:
{
  Gui, Main:+Disabled ; Disables the Main gui so the user can't make changes while in preferences.

  Gui, Preferences:New, HwndPreferencesHandle +Resize +OwnerMain, Preferences
  Gui, Add, GroupBox, w200 h3 vPreferences_UserInfo_Groupbox, User Information


  Gui, Add, Text, Section vPreferences_Username_Text, Username:
  Gui, Add, Text, vPreferences_Password_Text, Password:
  Gui, Add, Text, vPreferences_ConfirmPassword_Text, Confirm Password:

  Gui, Add, Edit, ys w135 vPreferences_Username_Edit Uppercase,
  Gui, Add, Edit, w135 vPreferences_Password_Edit Password,
  Gui, Add, Edit, w135 vPreferences_ConfirmPassword_Edit Password,


  Gui Show, w800 h600, Preferences
} Return

PreferencesGuiSize:
{
  GuiControl, Preferences:Move, Preferences_Username_Text, % "X" margin*1.5 "Y" margin*2.5

  GuiControlGet, Preferences_Username_Text, Pos
  GuiControl, Preferences:Move, Preferences_Username_Edit, % "X" Preferences_Username_TextX + Preferences_Username_TextW + (margin) "Y" Preferences_Username_TextY

  GuiControlGet, Preferences_Username_Edit, Pos
  GuiControl, Preferences:Move, Preferences_Password_Text, % "X" Preferences_Username_TextX "Y" Preferences_Username_TextY + Preferences_Username_EditH + 5
  GuiControlGet, Preferences_Password_Text, Pos
  GuiControl, Preferences:Move, Preferences_Password_Edit, % "X" Preferences_Password_TextX + Preferences_Password_TextW "Y" Preferences_Password_TextY


  GuiControl, Preferences:Move, Preferences_ConfirmPassword_Text, % "X" Preferences_Username_TextX
  GuiControlGet, Preferences_ConfirmPassword_Text, Pos
  GuiControl, Preferences:Move, Preferences_ConfirmPassword_Edit, % "X" Preferences_ConfirmPassword_TextX + Preferences_ConfirmPassword_TextW


  GuiControlGet, Preferences_ConfirmPassword_Edit, Pos
  GuiControl, Preferences:Move, Preferences_UserInfo_Groupbox, % "H" Preferences_ConfirmPassword_EditY + Preferences_ConfirmPassword_EditH + (margin/2) "W" Preferences_ConfirmPassword_EditX + Preferences_ConfirmPassword_EditW

} Return

PreferencesGuiClose:
{
  Gui, Main:-Disabled
  Gui, Preferences:Destroy
} Return


; Easy Window Dragging (requires XP/2k/NT)
; https://www.autohotkey.com
; Normally, a window can only be dragged by clicking on its title bar.
; This script extends that so that any point inside a window can be dragged.
; To activate this mode, hold down CapsLock or the middle mouse button while
; clicking, then drag the window to a new position.

; Note: You can optionally release CapsLock or the middle mouse button after
; pressing down the mouse button rather than holding it down the whole time.
; This script requires v1.0.25+.


~MButton & LButton::
CapsLock & LButton::
  CoordMode, Mouse  ; Switch to screen/absolute coordinates.
  MouseGetPos, EWD_MouseStartX, EWD_MouseStartY, EWD_MouseWin
  WinGetPos, EWD_OriginalPosX, EWD_OriginalPosY,,, ahk_id %EWD_MouseWin%
  WinGet, EWD_WinState, MinMax, ahk_id %EWD_MouseWin%
  if EWD_WinState = 0  ; Only if the window isn't maximized
  SetTimer, EWD_WatchMouse, 10 ; Track the mouse as the user drags it.
  return

  EWD_WatchMouse:
  GetKeyState, EWD_LButtonState, LButton, P
  if EWD_LButtonState = U  ; Button has been released, so drag is complete.
  {
    SetTimer, EWD_WatchMouse, Off
    return
  }
  GetKeyState, EWD_EscapeState, Escape, P
  if EWD_EscapeState = D  ; Escape has been pressed, so drag is cancelled.
  {
    SetTimer, EWD_WatchMouse, Off
    WinMove, ahk_id %EWD_MouseWin%,, %EWD_OriginalPosX%, %EWD_OriginalPosY%
    return
  }
  ; Otherwise, reposition the window to match the change in mouse coordinates
  ; caused by the user having dragged the mouse:
  CoordMode, Mouse
  MouseGetPos, EWD_MouseX, EWD_MouseY
  WinGetPos, EWD_WinX, EWD_WinY,,, ahk_id %EWD_MouseWin%
  SetWinDelay, -1   ; Makes the below move faster/smoother.
  WinMove, ahk_id %EWD_MouseWin%,, EWD_WinX + EWD_MouseX - EWD_MouseStartX, EWD_WinY + EWD_MouseY - EWD_MouseStartY
  EWD_MouseStartX := EWD_MouseX  ; Update for the next timer-call to this subroutine.
  EWD_MouseStartY := EWD_MouseY
Return



Exit:
MainGuiClose:
FileExit:
{
  ExitApp
} Return
