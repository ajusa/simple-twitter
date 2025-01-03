import strutils, os, mummy, mummy/routers, webby, debby/sqlite, nimja

type Post* = ref object
  id*: int
  content*: string

let db = openDatabase(":memory:")
db.createTable(Post)
db.insert(Post(content: "hello"))

proc postId(params: PathParams): int = params.getOrDefault("id", "0").parseInt

proc toPost(params: PathParams, body: string): Post =
  Post(id: params.postId(), content: body.parseSearch["content"])

proc index(params: PathParams, posts: seq[Post]): string =
  tmplf("template.nimja", baseDir = getScriptDir())

using req: Request
proc respond(req; resp: string) = req.respond(200, @[("Content-Type", "text/html")], resp)
proc redirect(req; url: string) = req.respond(302, @[("Location", url)])
var router: Router
router.get "/", proc (req) =
  req.respond(req.pathParams.index(db.filter(Post)))

router.post "/posts", proc (req) =
  db.insert(req.pathParams.toPost(req.body))
  req.redirect("/")

router.get "/posts/@id/edit", proc (req) =
  req.respond(req.pathParams.index(db.filter(Post)))

router.post "/posts/@id", proc (req) =
  db.update(req.pathParams.toPost(req.body))
  req.redirect("/")

router.post "/posts/@id/delete", proc (req) =
  db.delete(Post(id: req.pathParams.postId))
  req.redirect("/")

echo "Serving on http://localhost:8080"
newServer(router).serve(Port(8080))
