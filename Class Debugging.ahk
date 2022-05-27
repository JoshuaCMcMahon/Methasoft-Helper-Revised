

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
    global Debug_Listview

    Gui, Debug:New, Resize, % WindowName

    Gui, Add, ListView, vDebug_Listview, Timestamp|Clinic|Message

    if(GuiOptions != "")
    {
      Gui, % GuiOptions
    }
    ; Gui, Hide, w800 h600

    DebugGuiSize:
    {

      if(A_GuiWidth != "" AND A_GuiHeight != "")
      {
        GuiControl, Debug:MoveDraw, Debug_Listview, % "w" A_GuiWidth - 20 "h" A_GuiHeight - 20
      }
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
    LV_Add("Vis", TimeNow1 TimeNow[2] " " TimeNow3, clinic, message)
    LV_ModifyCol()
    LV_Modify(LV_GetCount(), "vis")

    ; Set the current defaults for the gui and listviews to their previous values
    Gui, % currentGui ":Default"
    Gui, Listview, % currentListview
    Gui, Treeview, % currentTreeview

  }

}

F12::
{
  Gui, Debug:Show, w800 h600
  ; debug.print(,"Show the debug window.")
} Return
