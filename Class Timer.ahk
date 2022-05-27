Class Timer
{
  __New(object, method, parameters := "")
  {

    debug.print(object.name, "Timer.__New() - __New() called for " method "().")


    ; object.timers[method] := {}

    this.object := object
    this.method := method
    this.parameters := parameters
    this.BoundObject := ObjBindMethod(object, method, parameters)
    this.status := "On"



    BoundObject := this.BoundObject



    SetTimer, % BoundObject, 250

  }

  __Delete()
  {

  }

  Start(object, method, parameters := "")
  {

    debug.print(object.name, "Timer.Start() - Start() called for " method "().")


    if(IsObject(object.timers[method]) = 1 AND object.timers[method].status = "Off")
    {
      ; start the timer.
      debug.print(object.name, "Timer.Start() - Timer exists for " method " and is off; turning on timer.")

      object.timers[method].status := "On"
      BoundObject := object.timers[method].BoundObject
      SetTimer, % BoundObject, On
    }
    else
    {
      if(object.HasKey("timers") = 0)
      {
        object.timers := {}
      }

      debug.print(object.name, "Timer.Start() - Timer doesn't exist for " method " or is off; crating new timer.")
      object.timers[method] := new Timer(object, method, parameters)
    }


  }

  Stop(object, method, parameters := "")
  {
    debug.print(object.name, "Timer.Stop() - Stop() called for " method "().")
    if(object.timers[method].status = "On")
    {
      object.timers[method].status := "Off"
      BoundObject := object.timers[method].BoundObject
      SetTimer, % BoundObject, Off
    }
  }

  Delete(object, method, parameters := "")
  {
    debug.print(object.name, "Timer.Delete() - Delete() called for " method "().")

    if(IsObject(object.timers[method]))
    {

      BoundObject := object.timers[method].BoundObject
      SetTimer, % BoundObject, Delete
      object.timers[method].Delete(BoundObject)
      object.timers.Delete(method)
      debug.print(object.name, "Timer.Delete() - Delete() finished for " method "().")
    }
  }

  DeleteAll(object)
  {
    debug.print(object.name, "Timer.DeleteAll() - DeleteAll() called.")

    keysArray := []

    for key, value in object.timers
    {
      debug.print(, key)
      keysArray.push(, key)
    }

    for index, value in keysArray
    {
      Timer.Delete(object, value)
    }


  }

  GetData(object, method, parameters := "")
  {
    debug.print(object.name, "Timer.GetData() - GetData() called.")
    msgbox, % object.timers[method].method
  }
}
