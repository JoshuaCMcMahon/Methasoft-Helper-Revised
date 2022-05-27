


MainGUI:
{
  ; Creates a new gui with a HWND variable HelperHandle. If you need to act on this instance of the helper, you should use "ahk_id %HelperHandle%" whenever possible.
  debug.print("Initialzing Main Gui...")

  ; Display Splash Screen
  Gui, Splash:New, HwndSplashWindow
  Gui, +AlwaysOnTop -SysMenu +Owner -Caption  ; +Owner avoids a taskbar button.
  Gui, Font, s24
  Gui, Add, Text, vSplashText, Methasoft Helper Loading...
  Gui, Font
  Gui, Splash:Show, NoActivate Center, Methasoft Helper  ; NoActivate avoids deactivating the currently active window.

  CheckReleases()

  Gui, Main:New, HwndHelperHandle, Methasoft Helper


  ; Menu Bar Section
  /*
  Menu, Helpers, Add, Add/Remove Employees, FileExit
  Menu, Helpers, Add, Billing, FileExit
  Menu, Helpers, Add, Forms, FileExit

  Menu, Options, Add, Preferences, Preferences_Window

  Menu, MainMenuBar, Add, Helpers, :Helpers
  Menu, MainMenuBar, Add, Options, :Options
  Gui, Menu, MainMenuBar
  */

  ; Login Section
  Gui, Add, Tab3, vLogin_Tab Section, Login

  Gui, Add, Text, Section vClinic_Text, Clinic:
  Gui, Add, DropDownList, x+m vClinic_Dropdown Sort gClinic_Progress HwndClinic_Dropdown_HWND,
  ; Gui, Add, Button, x+m gFilterGUI vFilter_Button, Filter

  Gui, Add, Progress, xs h8 c0078d7 vClinic_Progress, 0

  Gui, Add, CheckBox, % "xs vAutoadvance_Checkbox Checked" ini_file.Autoadvance, Autoadvance to Next Clinic after Login

  Gui, Add, Text, xs vUsername_Text, Username:
  Gui, Add, Edit, w100 x+m vUsername_Edit Uppercase, % ini_file.Username

  Gui, Add, Text, xs vPassword_Text, Password:
  Gui, Add, Edit, w100 x+m vPassword_Edit Password, % ini_file.Password

  Gui, Add, CheckBox, xs vChangePassword_Checkbox, Change Methasoft Password on Login

  Gui, Add, Button, xs Default w80 r2 vLogin_Button gLogin_Button, Login
  Gui, Add, Button, x+m w80 r2 vExit_Button gExit, Exit

  ; Active Methasoft Sessions
  Gui, Add, Tab3, vActiveSessions_Tab, Active Methasoft Sessions

  ; Gui, Add, ListView, r3 vActiveSessions_Listview Checked -Hdr, Name
  Gui, Add, Treeview, r3 vActiveSessions_Treeview Checked -Lines
  Gui, Add, Button, w180 vShowActive_Button xs, Show Active Database

  ; Gui, Filter:New,, Clinic Filters
  Gui, Add, Tab3, vFilters_Tab ys, Clinic Filters|Filters
  Gui, Tab, Clinic Filters
  Gui, Add, ListView, vFilter_Listview w400 h300 Checked Count200 AltSubmit gListviewEvent, Name|Legacy/M2M|Type|Zone|Region|State|Version
  Gui, Add, Button, xs w80 gApply vApplyButton, Apply
  Gui, Add, Button, x+m w80 gHide vHideButton, Hide
  Gui, Add, Button, x+m gOpenCheckedClinics vOpenCheckedClinicsButton, Open All Checked Clinics
  Gui, Tab, Filters
  quickWidth := 100
  Gui, Add, ListView, Section r10 w%quickWidth% Checked vFilters_LegacyM2M_Listview AltSubmit gListviewEvent, M2M/Legacy
  Gui, Add, ListView, ys r10 w%quickWidth% Checked vFilters_Type_Listview AltSubmit gListviewEvent, Type
  Gui, Add, ListView, ys r10 w%quickWidth% Checked vFilters_Version_Listview AltSubmit gListviewEvent, Version
  Gui, Add, ListView, Section xs r10 w%quickWidth% Checked vFilters_Zone_Listview AltSubmit gListviewEvent, Zone
  Gui, Add, ListView, ys r10 w%quickWidth% Checked vFilters_Region_Listview AltSubmit gListviewEvent, Region
  Gui, Add, ListView, ys r10 w%quickWidth% Checked vFilters_State_Listview AltSubmit gListviewEvent, State
  Gui, Add, Button, xs w80 vFilters_ApplyFilters_Button gApplyFilters, Apply Filters





  Gui, Tab
  ; Gui, Add, Slider, vMySlider Range0-10000 gresizeLeftPane, 300
  ; GuiControl, Hide, MySlider

  ; Add Statusbar and Show Window
  Gui, Add, StatusBar, vStatusbar, Ready to help!
  Gui, +Resize MinSize244x372 +AlwaysOnTop
  GoSub MainGuiSize ; Resize the gui elements before showing the window

  Gosub Filters

  SB_SetText("Ready to help! :D")

  Gui, Splash:Destroy
  Gui, Main:Show, w300 h500, Methasoft Helper
  Gui, Main:Default
  debug.print("Main Gui Initialized.")
} Return


; Main Gui Resize
MainGuiSize:
{

  windowWidth_swap := 500
  LeftWindow_size := 300

  if(A_GuiWidth > windowWidth_swap)
  {
    GuiControl, Show, Filters_Tab
    ; GuiControl, Show, MySlider
    GuiControlGet, Login_Tab, Pos
    margin := Login_TabX



    GuiControl, Main:Move, Login_Tab, % "W" LeftWindow_size
    GuiControlGet, Login_Tab, Pos

    GuiControl, Main:MoveDraw, Clinic_Dropdown, % "W" Login_TabW - Clinic_TextW - (margin*3)
    ; GuiControl, Main:MoveDraw, Filter_Button, % "X" A_GuiWidth - (margin * 3) - Filter_ButtonW

    GuiControl, Main:Move, Clinic_Progress, % "W" Login_TabW - (margin * 2)

    GuiControlGet, Username_Text, Pos
    GuiControl, Main:Move, Username_Edit, % "W" Login_TabW - Username_TextW - (margin*3)

    GuiControlGet, Password_Text, Pos
    GuiControl, Main:Move, Password_Edit, % "W" Login_TabW - Password_TextW - (margin*3)

    ButtonWidth := (Login_TabW - (margin*3))/2

    GuiControl, Main:Move, Login_Button, % "W" ButtonWidth
    GuiControl, Main:Move, Exit_Button, % "W" ButtonWidth " X" ButtonWidth + (margin*2)

    ; GuiControlGet, MySlider, Pos
    GuiControlGet, Autoadvance_Checkbox, Pos
    ; GuiControl, % "+Range" Autoadvance_CheckboxW + (margin*2) "-" A_GuiWidth - (margin*3) - Autoadvance_CheckboxW, MySlider

    ; GuiControlGet, MySlider
    ; ToolTip, % MySlider

    GuiControl, Main:Move, ActiveSessions_Tab, % "W" Login_TabW "H" A_GuiHeight - ActiveSessions_TabY - StatusBarH - margin  ; - (margin*2) + ShowActive_ButtonH
    GuiControlGet, ActiveSessions_Tab, Pos
    GuiControl, Main:Move, ActiveSessions_Treeview, % "W" ActiveSessions_TabW - (margin*2) " H" ActiveSessions_TabH - (margin*4) - ShowActive_ButtonH ; A_GuiHeight - ActiveSessions_ListviewY - (margin*2) ; - ShowActive_ButtonH

    GuiControlGet, ActiveSessions_Treeview, Pos
    GuiControl, Main:Move, ShowActive_Button, % "X" + margin "W" ActiveSessions_TreeviewW " Y" ActiveSessions_TreeviewH + margin ; "Y" ActiveSessions_TabH - ShowActive_ButtonH  ;  "Y" ActiveSessions_TabH - ShowActive_ButtonH - (margin*2)

    GuiControl, Main:Move, Filters_Tab, % "Y" margin/2 "X" Login_TabW + margin*2 "W" A_GuiWidth - Login_TabW - (margin*3) "H" A_GuiHeight - (margin*4)

    GuiControlGet, Filters_Tab, Pos
    GuiControlGet, ApplyButton, Pos
    GuiControl, Main:Move, Filter_Listview, % "W" Filters_TabW - (margin*2) "H" Filters_TabH - ApplyButtonH - (margin*4)

    GuiControlGet, Filter_Listview, Pos
    GuiControl, Main:Move, ApplyButton, % "Y" Filter_ListviewH + margin "X" margin

    GuiControlGet, ApplyButton, Pos
    GuiControl, Main:Move, HideButton, % "Y" Filter_ListviewH + margin "X" ApplyButtonW + (margin*2)

    GuiControlGet, HideButton, Pos
    GuiControl, Main:Move, OpenCheckedClinicsButton, % "Y" Filter_ListviewH + margin "X" ApplyButtonW + HidebuttonW + (margin*3)


    GuiControlGet, Filters_Tab, Pos
    GuiControlGet, Filters_LegacyM2M_Listview, Pos

    filter_listboxes_width := (Filters_TabW - margin*4)/3

    GuiControl, Main:Move, Filters_LegacyM2M_Listview, % "W" filter_listboxes_width
    GuiControl, Main:Move, Filters_Type_Listview, % "W" filter_listboxes_width "X" filter_listboxes_width + (margin*2)
    GuiControl, Main:Move, Filters_Version_Listview, % "W" filter_listboxes_width "X" (filter_listboxes_width * 2 ) + (margin*3)

    GuiControl, Main:Move, Filters_Zone_Listview, % "W" filter_listboxes_width
    GuiControl, Main:Move, Filters_Region_Listview, % "W" filter_listboxes_width "X" filter_listboxes_width + (margin*2)
    GuiControl, Main:Move, Filters_State_Listview, % "W" filter_listboxes_width "X" (filter_listboxes_width * 2 ) + (margin*3)


    ; GuiControl, Main:Move, MySlider, % "X" Login_TabX + Autoadvance_CheckboxW "Y" Filters_TabH + margin "W" A_GuiWidth - (margin*3) - Autoadvance_CheckboxW
  }
  else
  {
    GuiControl, Hide, Filters_Tab
    GuiControl, Hide, MySlider
    GuiControlGet, Login_Tab, Pos
    margin := Login_TabX

    GuiControlGet, Clinic_Text, Pos
    GuiControlGet, Clinic_Dropdown, Pos
    ; GuiControlGet, Filter_Button, Pos

    GuiControlGet, Username_Text, Pos
    GuiControlGet, Password_Text, Pos

    GuiControlGet, ActiveSessions_Tab, Pos
    GuiControlGet, ActiveSessions_Listview, Pos
    GuiControlGet, ShowActive_Button, Pos

    GuiControlGet, Statusbar, Pos

    GuiControl, Main:MoveDraw, Login_Tab, % "W" A_GuiWidth - (margin * 2)
    GuiControl, Main:MoveDraw, Clinic_Dropdown, % "W" A_GuiWidth - (margin * 5) - Clinic_TextW
    ; GuiControl, Main:MoveDraw, Filter_Button, % "X" A_GuiWidth - (margin * 3) - Filter_ButtonW

    GuiControl, Main:MoveDraw, Clinic_Progress, % "W" A_GuiWidth - (margin * 4)

    GuiControl, Main:MoveDraw, Username_Edit, % "W" A_GuiWidth - (margin * 5) - Username_TextW
    GuiControl, Main:MoveDraw, Password_Edit, % "W" A_GuiWidth - (margin * 5) - Password_TextW

    ButtonWidth := (A_GuiWidth - (margin * 5))/2

    GuiControl, Main:MoveDraw, Login_Button, % "W" ButtonWidth
    GuiControl, Main:MoveDraw, Exit_Button, % "W" ButtonWidth " X" ButtonWidth + (margin*2)

    GuiControl, Main:MoveDraw, ActiveSessions_Tab, % "W" A_GuiWidth - (margin*2) "H" A_GuiHeight - ActiveSessions_TabY - StatusBarH - margin ; - (margin*2) + ShowActive_ButtonH
    GuiControlGet, ActiveSessions_Tab, Pos
    GuiControl, Main:MoveDraw, ActiveSessions_Treeview, % "W" A_GuiWidth - (margin*4) " H" ActiveSessions_TabH - (margin*4) - ShowActive_ButtonH ; A_GuiHeight - ActiveSessions_ListviewY - (margin*2) ; - ShowActive_ButtonH

    GuiControlGet, ActiveSessions_Treeview, Pos
    GuiControl, Main:MoveDraw, ShowActive_Button, % "X" + margin "W" A_GuiWidth - (margin*4) " Y" ActiveSessions_TreeviewH + margin ; "Y" ActiveSessions_TabH - ShowActive_ButtonH  ;  "Y" ActiveSessions_TabH - ShowActive_ButtonH - (margin*2)
  }

} Return
