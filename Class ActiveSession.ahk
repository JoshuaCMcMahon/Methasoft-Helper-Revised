class ActiveSession
{

  Static Sessions := {}



  __New(clinic_name)
  {
    Critical, On
    Gui, Main:Default
    Gui, Treeview, ActiveSessions_Treeview
    debug.print(clinic_name, "ActiveSession.__New() called.")
    this.name := clinic_name

    this.ID := TV_Add(clinic_name, 0, "Sort")



    RowNumber := CSV_MatchCellColumn("Filter_List", clinic_name, 1)
    this.version := CSV_ReadCell("Filter_List", RowNumber, 9)
    this.URL := CSV_ReadCell("Filter_List", RowNumber, 3)

    ; Open a new Methasoft window and record the data to the database
    Run, % this.version "\Methasoft.Client.exe", % this.version "\Methasoft.Client.exe", UseErrorLevel, MethasoftPID
    if(ErrorLevel = "ERROR")
    {
      ; Send some sort of error to the console or statusbar.
      msgbox, Can't find Methasoft Folder.
      ActiveSession.Sessions[this.name] := ""
      ActiveSession.Sessions[this] := ""

    }
    this.PID := MethasoftPID

    debug.Print(this.name, this.name " created! ID: " this.ID ", Version: " this.version ", URL: " this.URL ", PID: " this.PID)
    debug.print(this.name, "ActiveSession.WaitLoginScreen() - Start MethasoftClosed Timer.")
    Timer.Start(this, "MethasoftClosed") ; Start the timer to see if Methasoft is closed.
    debug.print(this.name, "WaitLoginScreen Timer started.")
    Timer.Start(this, "WaitLoginScreen")
    debug.print(this.name, "ExceptionManagement Timer started.")
    Timer.Start(this, "ExceptionManagement")
    debug.print(clinic_name, "ActiveSession.__New() finished.")

  }

  __Delete()
  {
    ; Remove the entry from the active sessions list
    debug.print(this.name, "ActiveSession.__Delete() called.")
    Gui, Main:Default
    Gui, Treeview, ActiveSessions_Treeview
    TV_Delete(this.ID)
    ActiveSession.Sessions.Delete(this.name)
    debug.print(this.name, "ActiveSession.__Delete() finished.")
  }

  NewSession(clinic_array)
  {

    for index, value in clinic_array
    {
      debug.print(value, "ActiveSession.NewSession() called.")
    }



    For index, clinicName in clinic_array
    {
      For key, value in ActiveSession.Sessions
      {
        if(clinicName = key)
        {
          debug.print(key, "ActiveSession.NewSession() - Session exists; make this the active window.")
          DetectHiddenWindows, Off ; Needed to make sure we only bring the main Methasoft window to the foreground.
          WinActivate, % "ahk_pid " ActiveSession.Sessions[key].PID
          DetectHiddenWindows, On ; Reverse the previous setting right above.
          clinic_array.RemoveAt(1)
          Break
        }
      }
    }

    For index, clinicName in clinic_array
    {
      debug.print(clinicName, "ActiveSession.NewSession() - Start new active session.")
      ActiveSession.Sessions[clinicName] := new ActiveSession(clinicName)
    }

  }

  MethasoftClosed()
  {
    Process, Exist, % this.PID
    Methasoft_Exists := ErrorLevel
    if(Methasoft_Exists = 0)
    {
      debug.print(this.name, "ActiveSession.MethasoftClosed() exicuting.")
      this.EndSession()
    }
  }

  WaitLoginScreen()
  {
    Static LoginAttempts := 1



    if(WinExist("ahk_pid " this.pid, "Sign-in name:")) ; if the Login window exists
    {
      debug.print(this.name, "ActiveSession.WaitLoginScreen() - Login Screen Found.")
      ; Critical, On
      debug.print(this.name, "ActiveSession.WaitLoginScreen() - Stop WaitLoginScreen Timer.")
      Timer.Stop(this, "WaitLoginScreen")


      Gui Main:Default
      GuiControlGet, Username_Edit
      GuiControlGet, Password_Edit


      ; Enter the user credientals
      Sleep, 100
      debug.print(this.name, "ActiveSession.WaitLoginScreen() - Entering user credentials...")
      ControlGet, dropdown_visible, Visible ,, WindowsForms10.COMBOBOX.app.0.13965fa_r7_ad11, % "ahk_pid " this.PID

      clinic_name := CSV_MatchCellColumn("Filter_List", this.name, 1)
      dropdown_text := CSV_ReadCell("Filter_List", clinic_name, 2)

      Control, ChooseString, % dropdown_text, % controls[this.version].RemoteServer_Combobox_LoginWindow, % "ahk_pid " this.PID
      ControlSetText, % controls[this.version].Username_Edit_LoginWindow, % Username_Edit, % "ahk_pid " this.PID ; Test Values
      ControlSetText, % controls[this.version].Password_Edit_LoginWindow, % Password_Edit, % "ahk_pid " this.PID ; Test Values

      ; Validate the information is correct
      debug.print(this.name, "ActiveSession.WaitLoginScreen() - Validating user credentials...")
      ControlGetText, Clinic_Dropdown_Validate, % controls[this.version].RemoteServer_Combobox_LoginWindow, % "ahk_pid " this.PID
      ControlGetText, Username_Validate, % controls[this.version].Username_Edit_LoginWindow, % "ahk_pid " this.PID
      ControlGetText, Password_Validate, % controls[this.version].Password_Edit_LoginWindow, % "ahk_pid " this.PID

      if(Clinic_Dropdown_Validate = dropdown_text AND Username_Validate = Username_Edit AND Password_Validate = Password_Edit)
      {
        ; if all the values match, click the enter button
        debug.print(this.name, "ActiveSession.WaitLoginScreen() - Cridentials entered successfully.")
        Sleep, 100
        Control, Check,, % controls[this.version].SignIn_Button_LoginWindow, % "ahk_pid " this.PID
      }
      else
      {
        ; msgbox, Failed validation, enter creds manually
        debug.print(this.name, "ActiveSession.WaitLoginScreen() - Entering credientals failed " LoginAttempts " time(s); trying again.")
        LoginAttempts += 1
        Timer.Start(this, "WaitLoginScreen")
        Return
      }

      debug.print(this.name, "ActiveSession.WaitLoginScreen() - Delete WaitLoginScreen Timer.")
      Timer.Delete(this, "WaitLoginScreen") ; Delete this timer
      debug.print(this.name, "ActiveSession.WaitLoginScreen() - Start MethasoftOpened Timer.")
      Timer.Start(this, "MethasoftOpened")

      ; WinSet, Bottom ,, % "ahk_pid" this.pid

      if(ini_file.AutocloseNightlyProcesses)
      {
        debug.print(this.name, "ActiveSession.WaitLoginScreen() - Start NightlyProcessesCheck Timer.")
        Timer.Start(this, "NightlyProcessesCheck")
      }

    }
  }

  ExceptionManagement()
  {
    static WinTitle := "Netalytics.Framework.ExceptionManagement"
    static WinText := "Unable to cast object of type 'System.Security.Principal.GenericPrincipal' to type 'Netalytics.Framework.Remote.Interface.RemotePrincipal'."

    if(WinExist(WinTitle "ahk_pid" this.pid, WinText)) ; If the window exists
    {
      if(WinExist("ahk_pid" this.pid, "Sign-in name:") = 0) ; if the main login window doesn't exist.
      {
        debug.print(this.name, "ActiveSession.ExceptionManagement() - Exception found before login screen could load.")
        WinClose
        WinWait, % WinTitle "ahk_pid" this.pid, % WinText
        WinClose
        this.EndSession()
        ; Need to add code to retry session if it fails like this.
      }
      else
      {
        debug.print(this.name, "ActiveSession.ExceptionManagement() - Exception found after login screen loaded; closing error.")
        WinClose, % WinTitle "ahk_pid" this.pid, % WinText
      }
    }
  }



  NightlyProcessesCheck()
  {
    if(WinExist("Nightly Processes Check ahk_pid" this.pid))
    {
      debug.print(this.name, "ActiveSession.NightlyProcessesCheck() - Nightly Processes Check window found; closing window.")
      WinClose, % "Nightly Processes Check ahk_pid" this.pid
      debug.print(this.name, "ActiveSession.NightlyProcessesCheck() - Delete NightlyProcessesCheck Timer.")
      Timer.Delete(this, "NightlyProcessesCheck")
    }
  }

  MethasoftOpened()
  {

    if(WinExist("Methasoft - " this.URL "/ahk_pid" this.pid))
    {
      debug.print(this.name, "ActiveSession.MethasoftOpened() - Methasoft Fully Loaded.")
      debug.print(this.name, "ActiveSession.MethasoftOpened() - Stop MethasoftOpened Timer.")
      Timer.Stop(this, "MethasoftOpened")
      WinRestore, % "Methasoft - " this.URL "/ahk_pid" this.pid
      ; WinMinimize, % "Methasoft - " this.URL "/ahk_pid" this.pid
      debug.print(this.name, "ActiveSession.MethasoftOpened() - Delete ExceptionManagement Timer.")
      Timer.Delete(this, "ExceptionManagement")
      debug.print(this.name, "ActiveSession.MethasoftOpened() - Delete NightlyProcessesCheck Timer.")
      Timer.Delete(this, "NightlyProcessesCheck")
      debug.print(this.name, "ActiveSession.MethasoftOpened() - Delete MethasoftOpened Timer.")
      Timer.Delete(this, "MethasoftOpened")
    }

  }

  EndSession()
  {
    debug.print(this.name, "ActiveSession.EndSession called.")
    Critical, On
    Timer.DeleteAll(this)
    ActiveSession.Sessions[this.name] := ""
  }

}
