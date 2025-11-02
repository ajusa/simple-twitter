import strutils, xmltree, mummy, webby, macros

type 
  Rody* = object
    request*: Request
    headers*: HttpHeaders
    status*: int
    body*: string
    path*: string
    undo*: seq[string]
  Halt* = ref object of ValueError

var r* {.threadvar.}: Rody

proc initRody*(request: Request) =
  r = Rody(request: request, path: request.path)

proc halt() = raise Halt()

proc push*(pattern: string): bool =
  if r.path.startsWith(pattern):
    r.path.removePrefix(pattern)
    r.undo.add(pattern)
    return true

proc pop*() = 
  r.path = r.undo.pop() & r.path


template match(meth: string, body: untyped) =
  if r.request.httpMethod == meth and r.path == "":
    body
    halt()

template find*(pattern: string, body: untyped) =
  if push(pattern):
    body
    pop()

template find*(t: typedesc[int], body: untyped) =
  var numStr = ""
  var i = 1
  while i < r.path.len and r.path[i].isDigit():
    numStr.add(r.path[i])
    inc i
  try:
    if push("/" & numStr):
      var it {.inject.} = numStr.parseInt()
      body
      pop()
  except Defect:
    pop()
    discard

template get*(body: untyped) = match("GET"): body
template post*(body: untyped) = match("POST", body)
template delete*(body: untyped) = match("DELETE", body)
template put*(body: untyped) = match("PUT", body)

proc resp*(body: string) =
  r.status = 200
  r.headers["Content-Type"] = "text/html"
  r.body = body

proc redirect*(path: string) =
  r.status = 302
  r.headers["Location"] = path

proc finish*() =
  r.request.respond(r.status, r.headers, r.body)

template route*(body: untyped): untyped =
  proc(request: Request) {.gcsafe.} =
    try:
      request.initRody()
      body
      r.status = 404
      finish()
    except Halt:
      finish()

proc params*(): seq[(string, string)] =
  if r.request.body.len > 0: result &= r.request.body.parseSearch.toBase
  result &= r.request.queryParams.toBase

template `@`*(key: string): string = params()[key]

proc safe*(s: varargs[string, `$`]): string = xmltree.escape(s[0])