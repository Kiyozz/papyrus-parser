Scriptname example extends Quest

Int Property modId  Auto
Int Property modCRC  Auto
Int Property mod_h2heqp  Auto
Int Property mod_h2idle  Auto
Int Property mod_h2hatkpow  Auto
Int Property mod_h2hatk  Auto
Int Property mod_h2hstag  Auto
Int Property mod_jump  Auto
Int Property mod_sneakmt  Auto
Int Property mod_sneakidle  Auto
Int Property mod_sprint  Auto
Int Property mod_shout  Auto
Int Property mod_mtx  Auto
Int Property mod_mt  Auto
Int Property mod_mtturn  Auto
Int Property mod_mtidle  Auto

String Property events_equip = "events__equip" Auto
String Property events_unequip = "events__unequip" Auto
String Property events_1_equip = "events_1_equip" Auto

Function Log(String prefix, String messageText)
  Debug.Trace("[Y]: " + prefix + ": " + messageText)
EndFunction

Function Notification(String messageText)
  Debug.Notification(messageText)
EndFunction

Function test()
    if true

    endif
EndFunction

Int Function test2()
    if active()

    endif
EndFunction

Event OnUpdate()

EndEvent

Event OnCustomEvent(string name)

EndEvent
