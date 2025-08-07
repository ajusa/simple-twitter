import macros, mummy, strutils, tables

macro paramsAsTuple(p: proc): untyped =
  result = nnkTupleTy.newTree()
  for x in p.getTypeImpl()[0][1..^1]:
    result.add newIdentDefs(ident $x[0], x[1])

macro unpackTuple(p: proc, t: tuple): untyped =
  result = newCall(p)
  for i, _ in t.getTypeInst():
    result.add nnkBracketExpr.newTree(t, newLit i)

import mummy/routers

proc parseHook(request: Request, key: string, v: var Request) =
  v = request

proc parseHook(request: Request, key: string, v: var string) =
  if key in request.pathParams:
    v = request.pathParams[key]
  else:
    v = request.queryParams[key]

proc parseHook[T: ref object](request: Request, key: string, v: var T) =
  v = new(T)
  let q = request.body.parseSearch
  for k, val in v[].fieldPairs:
    when val is string:
      val = q[k]

proc parseHook(request: Request, key: string, v: var bool) =
  v = key in request.queryParams

proc parseHook(request: Request, key: string, v: var int) =
  var str: string
  request.parseHook(key, str)
  v = parseInt(str)

proc toHandler(wrapped: proc): RequestHandler =
  var params: paramsAsTuple(wrapped)
  return proc(request: Request) =
    for k, v in params.fieldPairs:
      request.parseHook(k, v)
    when compiles(request.respondHook(wrapped.unpackTuple(params))):
      request.respondHook(wrapped.unpackTuple(params))
    else:
      wrapped.unpackTuple(params)

var procToRoute* = initTable[pointer, string]()
proc get*(router: var Router, path: string, p: proc) =
  procToRoute[cast[pointer](p)] = path
  router.get(path, p.toHandler())

proc post*(router: var Router, path: string, p: proc) =
  procToRoute[cast[pointer](p)] = path
  router.post(path, p.toHandler())

template link*(p: proc, args: tuple = ()): untyped =
  {.cast(gcsafe).}:
    var str = procToRoute[cast[pointer](p)]
    var query: QueryParams
    for k, v in args.fieldPairs:
      if "@"&k in str:
        str = str.replace("@"&k, $v)
      else:
        query[k] = $v
    if "@" in str:
      raise newException(ValueError, "Did not provide required path arguments")
    if query.len > 0:
      str & "?" & $query
    else:
      str

proc respondHook*(request: Request, body: string) =
  var headers: HttpHeaders
  headers["Content-Type"] = "text/html"
  request.respond(200, headers, body)

proc redirect*(request: Request, path: string, body = "") =
  request.respond(302, @[("Location", path)])

when isMainModule:
  proc indexHandler(request: Request) =
    request.respond(200, @[("Content-Type", "text/plain")], "Hello, World!")

  proc profileHandler(request: Request, userId: string) =
    # This is the authenticated endpoint for a user's profile.
    request.respond(200, @[("Content-Type", "text/plain")], "Hello " & userId)

  var router: Router
  router.get("/", indexHandler)
  router.get("/me", profileHandler)

  let server = newServer(router)
  echo "Serving on http://localhost:8080"
  server.serve(Port(8080))