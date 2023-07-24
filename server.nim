import strutils, strformat
import dekao, dekao/htmx, mummy, mummy/routers, webby, debby/sqlite, nails, nails/dekao_utils

type Post* = ref object
  id*: int
  content*: string

let db = openDatabase(":memory:")
db.createTable(Post)

proc getId(req: Request): int = req.query["id"].parseInt

proc form(post: Post) = 
  textarea: placeholder "Write here"; name "content"; say post.content

proc show(post: Post) = form:
  hxTarget "this"
  span: say post.content
  button: hxGet &"/posts/edit?id={post.id}"; say "Edit"
  button: hxDelete &"/posts?id={post.id}"; say "Delete"

proc edit(post: Post) = form:
  post.form()
  button: hxGet &"/posts?id={post.id}"; say "Cancel"
  button: hxPatch &"/posts?id={post.id}"; say "Update"

proc index(posts: seq[Post]) =
  html: lang "en"
  head:
    meta: charset "UTF-8"; name "viewport"; content "width=device-width, initial-scale=1"
    script: src "https://unpkg.com/htmx.org@1.6.1"
    title: say "Simple Twitter"
  body:
    tdiv "#posts":
      for post in posts: post.show()
    form:
      tdiv: Post().form()
      button: hxPost "/posts"; hxTarget "#posts"; hxSwap "beforeend"; say "Add"

proc indexHandler(req: Request): seq[Post] = db.filter(Post)

proc upsertHandler(req: Request): Post =
  result = Post(content: req.body.parseSearch["content"])
  if "id" in req.query: result.id = req.getId()
  db.upsert(result)

proc showHandler(req: Request): Post = db.get(Post, req.getId())

proc deleteHandler(req: Request) =
  db.delete(Post(id: req.getId()))
  req.respond(200, body = "")

var router: Router
router.get("/", indexHandler.renderWith(index))
router.post("/posts", upsertHandler.renderWith(show))
router.get("/posts/edit", showHandler.renderWith(edit))
router.patch("/posts", upsertHandler.renderWith(show))
router.get("/posts", showHandler.renderWith(show))
router.delete("/posts", deleteHandler)

let server = newServer(router)
echo "Serving on http://localhost:8080"
server.serve(Port(8080))