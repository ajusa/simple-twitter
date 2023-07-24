import strutils, strformat
import dekao, dekao/[htmx, mummy_utils], mummy, mummy/routers, webby, debby/sqlite

type Post* = ref object
  id*: int
  content*: string

let db = openDatabase(":memory:")
db.createTable(Post)
db.insert(Post(id: 0, content: "hello world!"))

proc getId(req: Request): int = req.uri.parseUrl.query["id"].parseInt

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

proc initPost(req: Request): Post =
  new result
  if "id" in req.uri.parseUrl.query: result.id = req.getId()
  let q = req.body.parseSearch()
  result.content = q["content"]

proc indexHandler(req: Request): seq[Post] = db.filter(Post)

proc createHandler(req: Request): Post =
  result = req.initPost()
  db.insert(result)

proc editHandler(req: Request): Post = db.get(Post, req.getId())

proc updateHandler(req: Request): Post =
  result = req.initPost()
  db.update(result)

proc showHandler(req: Request): Post = db.get(Post, req.getId())

proc deleteHandler(req: Request) =
  db.delete(Post(id: req.getId()))
  req.respond(200, body = "")

var router: Router
router.get("/", indexHandler.renderWith(index))
router.post("/posts", createHandler.renderWith(show))
router.get("/posts/edit", editHandler.renderWith(edit))
router.patch("/posts", updateHandler.renderWith(show))
router.get("/posts", showHandler.renderWith(show))
router.delete("/posts", deleteHandler)

let server = newServer(router)
echo "Serving on http://localhost:8080"
server.serve(Port(8080))