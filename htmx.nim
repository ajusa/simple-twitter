import taggy

proc hxGet*(value: string) = attr "hx-get", value
proc hxPost*(value: string) = attr "hx-post", value
proc hxTarget*(value: string) = attr "hx-target", value
proc hxSwap*(value: string) = attr "hx-swap", value
proc hxExt*(value: string) = attr "hx-ext", value
proc hs*(value: string) = attr "_", value
proc hxSwapOob*(value: bool) = attr "hx-swap-oob", $value
proc hxVars*[T](pairs: openArray[(string, T)]) =
  var finalValue = ""
  for (key, value) in pairs:
    finalValue &= key & ":" & $value & ","
  attr "hx-vars", finalValue
