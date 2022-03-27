import jsony, strutils

proc parseHook*(s: string, i: var int, v: var int64) =
  var str: string
  parseHook(s, i, str)
  v = str.parseInt()

template grab*(name: untyped, T: typedesc, body: untyped) {.dirty.} =
  var `name` {.inject.} = request.params.toJson.fromJson(T)
  body
