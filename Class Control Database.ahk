Class Methasoft_Controls
{
  __New()
  {

    debug.Print("", "Methasoft_Controls.__new() - Process Started.")
    ; Import the CSV File
    CSV_Load("Control Database.csv", "controlDatabase")
    ; this.testing := "testing variable"

    totalColumns := CSV_TotalCols("controlDatabase")
    ClassNN_Start := 6 ; What column does the ClassNN names start on.

    Methasoft_Versions := totalColumns - ClassNN_Start + 1

    ; Setup objects for each of the version of Methasoft in the csv file.
    Loop, % Methasoft_Versions
    {
      versionNumber := CSV_ReadCell("controlDatabase", 1, A_Index + ClassNN_Start - 1)
      this[versionNumber] := {}
    }

    ; Get Methasoft Class to determine the _r#_ value; needed to alter the control names based on the version of Windows
    debug.Print("", "Methasoft_Controls.__new() - Waiting for Methasoft.Client.exe to exist...")
    Process, Wait, Methasoft.Client.exe
    MethasoftPID := ErrorLevel
    Critical, On
    DetectHiddenWindows, Off
    WinWait, % "ahk_pid" MethasoftPID
    WinGetClass, MethasoftClass, % "ahk_pid" MethasoftPID
    RegExMatch(MethasoftClass, "_r\d+_" , MatchedPattern)
    debug.Print("", "Methasoft_Controls.__new() - Methasoft.Client.exe found; MatchedPattern is " MatchedPattern ".")
    DetectHiddenWindows, On

    Loop, % CSV_TotalRows("controlDatabase") - 1
    {
      if(A_Index != 1)
      {
        A_Index_Row := A_Index
        Loop, % Methasoft_Versions
        {

          ControlName := CSV_ReadCell("controlDatabase", A_Index_Row, 4)
          versionNumber := CSV_ReadCell("controlDatabase", 1, A_Index + ClassNN_Start - 1)

          UnmodifiedControl := CSV_ReadCell("controlDatabase", A_Index_Row, A_Index + ClassNN_Start - 1)

          ModifiedControl := RegExReplace(UnmodifiedControl, "_r\d+_" , MatchedPattern,, 1)

          this[versionNumber][ControlName] := ModifiedControl


        }
      }
    }

    debug.Print("", "Methasoft_Controls.__new() - Finished importing controls.")


  }

  __Delete()
  {

  }
}
