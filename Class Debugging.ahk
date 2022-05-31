

Class DebugClass
{



  __new(WindowName := "Debug", GuiOptions := "")
  {
    this.WindowName := WindowName
    this.GuiOptions := GuiOptions
    this.Gui(WindowName, GuiOptions)


  }

  __delete()
  {

  }

  Gui(WindowName, GuiOptions)
  {
    Global Debug_Listview
    Global DebugListview_Autoscroll_Checkbox
    Global Debug_Listview_Handle
    Global DebugListview_Autoscroll_Checkbox_Handle

    Gui, Debug:New, Resize, % WindowName

    Gui, Debug:Add, ListView, vDebug_Listview HwndDebug_Listview_Handle, Timestamp|Clinic|Message
    Gui, Debug:Add, CheckBox, vDebugListview_Autoscroll_Checkbox HwndDebugListview_Autoscroll_Checkbox_Handle Checked, Autoscroll Messages

    if(GuiOptions != "")
    {
      Gui, % GuiOptions
    }
    ; Gui, Hide, w800 h600

    DebugGuiSize:
    {
      currentGui := A_DefaultGui ; Get the current default gui
      Gui, Debug:Default

      if(A_GuiWidth != "" AND A_GuiHeight != "")
      {
        GuiControlGet, %DebugListview_Autoscroll_Checkbox_Handle%, Debug:Pos
        GuiControl, Debug:MoveDraw, Debug_Listview, % "w" A_GuiWidth - 20 "h" A_GuiHeight - 20 - %DebugListview_Autoscroll_Checkbox_Handle%H -10

        GuiControlGet, %Debug_Listview_Handle%, Debug:Pos
        GuiControl, Debug:MoveDraw, DebugListview_Autoscroll_Checkbox, % "Y" %Debug_Listview_Handle%Y + %Debug_Listview_Handle%H + 10
      }
      Gui, % currentGui ":Default"
    } Return

  }

  print(clinic := "", message := "")
  {
    ; Get the current defaults for the gui and listviews
    currentGui := A_DefaultGui
    currentListview := A_DefaultListView
    currentTreeview := A_DefaultTreeView



    Gui, Debug:Default
    Gui, ListView, Debug_Listview
    TimeNow := [A_Now, A_MSec, ""]

    FormatTime, TimeNow1, % TimeNow[1], M/d/yyyy h:mm:ss.
    FormatTime, TimeNow3, % TimeNow[1], tt

    ; msgbox, % A_MSec/1000 " | " TimeNow
    LV_Add(, TimeNow1 TimeNow[2] " " TimeNow3, clinic, message)
    LV_ModifyCol()

    GuiControlGet, DebugListview_Autoscroll_Checkbox
    if(DebugListview_Autoscroll_Checkbox)
    {
      LV_Modify(LV_GetCount(), "vis")
    }

    ; Set the current defaults for the gui and listviews to their previous values
    Gui, % currentGui ":Default"
    Gui, Listview, % currentListview
    Gui, Treeview, % currentTreeview

  }

}

F12::
{
  Gui, Debug:Show, w800 h600
} Return
