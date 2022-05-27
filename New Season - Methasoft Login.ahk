#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#Singleinstance Force


/**************************************
* Important Information
***************************************
*/

Global versionNumber := 8

Global ini_filename := "Helper.ini"



/**************************************
* #Include Supporting Files
***************************************
*/

#include csv.ahk



/**************************************
* Startup Operations
***************************************
*/



Class FieldDatabase
{

	__new(FileName)
	{

		; check to see if the file exists
		if(!FileExist(FileName))
		{
			msgbox, The Field Database file could not be found.
			return
		}

		CSV_Load(FileName)

		windowsVersions := []
		methasoftVersions := []


		; This loop iterates through the columns and adds all the different supported Methasoft and Windows version to the above arrays.
		Loop, % CSV_TotalCols("") - 5 ; Look at each column starting at the 5th column
		{

			CellData := CSV_ReadCell("", 1, A_Index+5)
			array := StrSplit(CellData, "|")

			for each, value in array
			{
				if(A_Index = 1)
				{
					if(ArrayUnique(value, windowsVersions))
					{
						windowsVersions.push(value)
					}
				}
				Else
				{
					if(ArrayUnique(value, methasoftVersions))
					{
						methasoftVersions.push(value)
					}
				}
			}
		}

		; This loop instaniates all the objects for each combination of windows and Methasoft versions.
		databaseCSVFile := A_WorkingDir . "\Methasoft Helper Fields - Methasoft Database.csv"
		this.field := {} ; instantiate the field object
		this.columnCount := windowsVersions.Count()+methasoftVersions.Count()+5 ; instaniate the column count
		for windowsIndex, windowsElement in windowsVersions ; for feach version of windows, do the following:
		{
			this.field[windowsElement] := {} ; instantiate an object for each version of windows in windowsVersions
			for methasoftIndex, methasoftElement in methasoftVersions
			{
				this.field[windowsElement][methasoftElement] := {} ; instantiate an object for each version of Methasoft
			}
		}

		; This section populates all the data from the database csv file.
		Loop, % CSV_TotalCols("") - 5
		{
			CellData := CSV_ReadCell("", 1, A_Index+5)
			array := StrSplit(CellData, "|")



		}

	}
}

ArrayUnique(newValue, array)
{
	for each, value in array
	{
		if(newValue = value)
		return 0 ; value is not unique
	}
	return 1 ; value is unique
}

ArrayToString(array, delimiter := "`n")
{
	string := ""
	for each, value in array
	{
		string .= value . delimiter
	}
	return string
}



database := new FieldDatabase("Field Database.csv")


/*
class FieldDatabase_old
{
	__New()
	{
		windowsVersions := ["WIN_7","WIN_10"] ; Listed windows versions
		methasoftVersions := [7143,7804] ; Listed Methasoft Versions
		databaseCSVFile := A_WorkingDir . "\Methasoft Helper Fields - Methasoft Database.csv"
		this.field := {} ; instantiate the field object
		this.columnCount := windowsVersions.Count()+methasoftVersions.Count()+5 ; instaniate the column count
		for windowsIndex, windowsElement in windowsVersions ; for feach version of windows, do the following:
		{
			this.field[windowsElement] := {} ; instantiate an object for each version of windows in windowsVersions
			for methasoftIndex, methasoftElement in methasoftVersions
			{
				this.field[windowsElement][methasoftElement] := {} ; instantiate an object for each version of Methasoft
			}
		}
		try
		{
			if(fileExist(databaseCSVFile)) = "" ; If the file doesn't exist, throw an error.
			{
				Throw "The database CSV file cannot be found.`nYou can find a link to the original Google Sheet below.:`n`nhttps://docs.google.com/spreadsheets/d/1Np0pRqh-SxSsp1I6LaafxjRqVmHP_hOl5kGupwuN-R0/edit?usp=sharing"
			}

			Loop, Read, %databaseCSVFile%
			{
				RegExReplace(A_LoopReadLine, "," , Replacement := ",", columnCount, Limit := -1, StartingPosition := 1) ; not sure what this is for...

				if(columnCount != this.columnCount) ; check to see if the number of columns is what was expected
				{
					Throw "The number of columns in the database doesn't match what was expected.`n`nExpected Column Count: " . this.columnCount . "`nActual Column Count: " . columnCount . "`n`nCheck the CSV file (found below) and update it to match the supported Windows & Methasoft versions.`n`n https://docs.google.com/spreadsheets/d/1Np0pRqh-SxSsp1I6LaafxjRqVmHP_hOl5kGupwuN-R0/edit?usp=sharing`n`nSupported Windows & Methasoft Versions: " . join(windowsVersions) . ", " . join(methasoftVersions)
				}
				lineData := [] ; instaniate the linedata variable with an array
				Loop, parse, A_LoopReadLine, CSV
				{
					if(A_Index >= 5) ; skip the first 4 columns
					{
						lineData.push(A_LoopField)
					}
				}
				lineDataCodename := lineData[1]
				lineData.RemoveAt(1)
				for arraySize, arrayElement in lineData
				{
					this.field[windowsVersions[(Ceil(A_Index/methasoftVersions.Count()))]][methasoftVersions[(MOD(A_Index-1,methasoftVersions.Count())+1)]][lineDataCodename] := lineData[(A_Index)]
				}
			}
		}
		catch, errorStatement
		{
			msgbox, %errorStatement%
			Return
		}
	}

	getWindowsVersion()
	{
		Switch A_OSVersion
		{
			Case "WIN_7", "WIN_8", "WIN_8.1", "WIN_VISTA", "WIN_2003", "WIN_XP", "WIN_2000" : windowsVersion := A_OSVersion
			default:
			windowsVersion := "WIN_" . substr(a_OSVersion, 1, 2)
		}
		return windowsVersion
	}

	getMethasoftVersion(MethasoftEXE)
	{
		FileGetVersion, versionNumber, %MethasoftEXE%
		versionNumber := RegExReplace(versionNumber, "\.", "")
		if(ErrorLevel != 1)
		{
			return versionNumber
		}
		else
		{
			return -1
		}
	}

	setMethasoftClass()
	{
		Return this.field[windowsVersion][methasoftVersion].Program_MethasoftClass_Window
	}
	getTest(testVariable := "test")
	{
		msgbox, % testVariable
	}

}
*/


; Load the Ini file
Class Preferences
{

	__new()
	{
		this.Load()
	}

	changesMade[]
	{
		get
		{
			if(this._changesMade = "")
			{
				this._changesMade := 0
			}

			return this._changesMade
		}
		set
		{
			this._changesMade := 1
		}
	}

	Save()
	{
		; Save the preferences
		this.Verify()

		; IniWrite, % this.username, % ini_filename, User, Username
	}
	Load()
	{
		IniRead, username, % ini_filename, User, Username, % ""
		IniRead, password, % ini_filename, User, Password, % ""
		this.username := username
		this.password := password
	}
	Verify()
	{
		; Make sure the sattings being saved can be saved.

		; Default Passswords
		GuiControlGet, DefaultPassword,, DefaultPassword
		GuiControlGet, ConfirmPassword,, ConfirmPassword
		if(DefaultPassword != ConfirmPassword)
		{
			msgbox, Passwords don't match.
		}
	}
}

Global preferences := New Preferences





; Load the Clinic List
Class ClinicList
{

	static message := ""

	total[]
	{
		get
		{
			return CSV_TotalRows("Clinic_List")
		}
	}

	__new()
	{
		if(FileExist("Clinic List.csv") != "")
		{
			CSV_Load("Clinic List.csv", "Clinic_List")
			this.message := CSV_TotalRows("Clinic_List") . " Databases Loaded"

		}
		else
		{
			; Failed to load file
			this.message := "Failed to find Clinic List.csv"
		}
	}



	prettyNames(delimiter := "|")
	{
		SB_SetText(this.message)
		return CSV_ReadCol("Clinic_List", 3, delimiter)
	}

	reload()
	{
		this.__new()
		SB_SetText("Database List Reloaded; " . this.message)
	}
}

Global clinicList := new ClinicList




class FileChanged {

	fn := ""
	running := ""
	filename := ""
	modifiedTime := ""

	__new(filename, period := 500)
	{
		this.filename := filename
		FileGetTime, modifiedTime, % this.filename, M
		this.modifiedTime := modifiedTime
		this.startTimer(period)
	}

	startTimer(period)
	{
		fn := this["timer"].bind(this)	; To delete the timer you need to save this reference.
		this.fn := fn
		this.running := 1
		setTimer, % fn, % period
	}

	timer()
	{
		FileGetTime, modifiedTime, % this.filename , M
		if(modifiedTime != this.modifiedTime)
		{
			this.pause()
			SoundPlay, *48
			msgbox, 8228, % "Reload File?", % this.filename . " was overwritten. Do you want to reload the file?"
			IfMsgBox, Yes
			{
				msgbox, pressed yes
			}
			FileGetTime, modifiedTime, % this.filename , M
			this.modifiedTime := modifiedTime
			this.resume()
		}
	}

	pause()
	{
		fn := this.fn
		setTimer, % fn, off
		this.running := 0

	}

	resume()
	{
		fn := this.fn
		setTimer, % fn, On
		this.running := 1
	}

	toggle()
	{

	}
}



iniFileChanged := New FileChanged(ini_filename)
MethasoftConfigChanged := New FileChanged("Methasoft 8130\Methasoft.Client.exe.config")




/**************************************
* New Season - Methasoft Login GUI
***************************************
*/

Gui, Color, White
Gui, Add, Picture, x0 y0 , loginBackground.png
Gui, Add, DropDownList, vRemoteServer w350 x108 y145 Sort, % clinicList.prettyNames()
Gui, Add, Button, Default x+5 w80 gReload, Reload
Gui, Add, Edit, x108 y200 w175 r1 vUsername Uppercase, % preferences.username
Gui, Add, Edit, x108 y255 w175 r1 vPassword Password, % preferences.password
Gui, Add, Button, Default x+5 w80 gLoginButton, Login
Gui, Add, Button, x+5 w80 gGuiClose, Exit
Gui, Add, CheckBox, vChangePassword x108 y+5, Change Methasoft Password
Gui, Add, Text, x580 y348 0x202 0x2 cGray , % "Version " . versionNumber
Gui, Add, StatusBar,, % clinicList.message
gosub ShowHelperFeatures ; Load the helper features subroutine
Gui, Show, w652 h399,New Season - Methasoft Login

; loadClinicList()
Return


/**************************************
* Methasoft Helper GUI
***************************************
*/

Gui, New,, Methasoft Helper
Gui, Show,, Methasoft Helper

/**************************************
* Hotkeys & Labels
***************************************
*/

GuiClose:
	ExitApp
Return

ShowHelperFeatures:
	; Shows the hidden Methasoft Helper features if the ini files exists.
	if(FileExist("Helper.ini") != "")
	{
		; Adds the Methasoft Helper Button & Preferences Button
		Gui, Add, Button, x10 y343, Methasoft Helper
		Gui, Add, Button, x+10 gPreferences, Preferences

		/*
		; Attaches the Menu to the Login Window
		Menu, FileMenu, Add, &Open`tCtrl+O, Open  ; See remarks below about Ctrl+O.
		Menu, FileMenu, Add, E&xit, Exit
		Menu, HelpMenu, Add, &About, About
		Menu, MyMenuBar, Add, &File, :FileMenu  ; Attach the two sub-menus that were created above.
		Menu, MyMenuBar, Add, &Help, :HelpMenu
		Gui, Menu, MyMenuBar

		Open:
			msgbox, Open
		Return

		Exit:
			msgbox, Exit
		Return

		About:
			msgbox, About
		Return
		*/
	}
Return

Preferences:
	; Gui +OwnDialogs
	Gui, Preferences:+owner1
	Gui, 1:+Disabled
	Gui, Preferences:Add, Tab3, w300 h200, User|Options
	Gui, Preferences:Add, StatusBar,,

	Gui, Preferences:Tab ; Future controls are not part of the tab groups
	Gui, Preferences:Add, Button, Section w80 xs gPreferencesSave, Save
	Gui, Preferences:Add, Button, w80 x+10 gPreferencesGuiClose, Close

	Gui, Preferences:Tab, User
	Gui, Preferences:Add, Text, Section, Default Username:
	Gui, Preferences:Add, Edit, vUsername w135 x+10 gPreferenceChanged, % preferences.username
	Gui, Preferences:Add, CheckBox, vRememberPassword xs, Remember Password
	Gui, Preferences:Add, Text, Section, Default Password:
	Gui, Preferences:Add, Text,, Comfirm Password:
	Gui, Preferences:Add, Edit, vDefaultPassword w135 ys gPreferenceChanged
	Gui, Preferences:Add, Edit, vConfirmPassword w135 gPreferenceChanged

	Gui, Preferences:Tab, Options
	Gui, Preferences:Add, Text,, Options Tab
	; Start Fullscreen
	; Start Windowed
	; Custom window resolution
	; Start on Default screen (screen mouse is on, or always a specicif screen)

	; Autoadvance Clinic List checked by default




	Gui, Preferences:Show ; Show the window

Return

PreferencesGuiClose:
	; Need to add a check to see if the user changed anything and to prompt to save if so.
	msgbox, % preferences.changesMade
	if(preferences.changesMade != 0)
	{
		msgbox, changes made.
	}
	Gui, 1:-Disabled
	Gui Preferences:Destroy
Return

+Escape::
	Reload
Return



/**************************************
* Functions
***************************************
*/

/*
loadClinicList(reload := 0)
{
	static clinic_list := ""

	if(reload != 0)
	{
		clinic_list := ""
	}

	if(clinic_list = "")
	{
		CSV_Load("Clinic List.csv", "Clinic_List")
		clinic_list := CSV_ReadCol("Clinic_List", 3, "|")
	}

	GuiControl, 1:, RemoteServer, % "|" . clinic_list
	SB_SetText(CSV_TotalRows("Clinic_List") . " Databases Loaded")
}
*/



LoginButton()
{
	GuiControlGet, username,, Username
	GuiControlGet, password,, Password
	GuiControlGet, RemoteServer,, RemoteServer
	; Get the reset password checked button



	SB_SetText("Logging In...")
	row := CSV_SearchColumn("Clinic_List", RemoteServer, 3)
	folder_location := CSV_ReadCell("Clinic_List", row, 1)
	server_address := CSV_ReadCell("Clinic_List", row, 2)
	if(FileExist(folder_location . "\Methasoft.Client.exe") = "")
	{
		SB_SetText("The Methasoft folder or exe is missing.")
		Return
	}

	Run, Methasoft.client.exe, % folder_location . "\",, Methasoft_PID

	WinWait, ahk_pid %Methasoft_PID%

	; Insert the information entered by the user.
	; ControlSetText, WindowsForms10.EDIT.app.0.13965fa_r7_ad11, JMCMAHON, ahk_pid %Methasoft_PID%
	ControlSetText, database.field[windowsVersion][methasoftVersion].LoginScreen_SigninName_Edit, % username, ahk_pid %Methasoft_PID%



}


PreferencesSave()
{
	; Can't figure out how BoundFunc Objects work, this is a workaround. More at https://www.autohotkey.com/docs/objects/Functor.htm#BoundFunc
	preferences.save()
}

Reload()
{
	clinicList.Reload()
}

PreferenceChanged()
{
	preferences.changesMade := 1
}
