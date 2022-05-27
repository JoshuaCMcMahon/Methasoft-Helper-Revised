
Load_INI()
{
  IniRead, Username, Helper.ini, User, Username, %A_Space%
  IniRead, Password, Helper.ini, User, Password, %A_Space%
  ini_file.Username := Username
  ini_file.Password := Password

  IniRead, Autoadvance, Helper.ini, Helper Preferences, Autoadvance, 1
  ini_file.Autoadvance := Autoadvance

  IniRead, AutocloseNightlyProcesses, Helper.ini, Methasoft Preferences, AutocloseNightlyProcesses, 1
  ini_file.AutocloseNightlyProcesses := AutocloseNightlyProcesses
}

Class INI
{

  settings := {}

  __New()
  {

  }

  __Delete()
  {

  }

  Read()
  {
    IniRead, OutputVar, Filename, Section, Key , Default
    IniRead, OutputVarSection, Filename, Section
    IniRead, OutputVarSectionNames, Filename
  }

  Write()
  {
    IniWrite, Value, Filename, Section, Key
    IniWrite, Pairs, Filename, Section
  }

  Delete()
  {
    IniDelete, Filename, Section , Key
  }

}
