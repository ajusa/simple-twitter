import strutils, strformat
import dekao, dekao/htmx, mummy, mummy/routers, nails, webby, debby/sqlite

type Post* = ref object
  id: int
  content*: string

let db = openDatabase(":memory:")
db.createTable(Post)
db.insert(Post(id: 0, content: "hello world!"))

proc getId(req: Request): int = req.query["id"].parseInt

template render(req: Request, body: untyped): untyped =
  let resp = render: body
  req.respond(200, @[("Content-Type", "text/html")], resp)

proc show(post: Post) = form:
  hxTarget "this"
  span: say post.content
  button: hxGet &"/posts/edit?id={post.id}"; say "Edit"
  button: hxDelete &"/posts?id={post.id}"; say "Delete"

proc edit(post: Post) = form:
  textarea: name "content"; say post.content
  button: hxGet &"/posts?id={post.id}"; say "Cancel"
  button: hxPatch &"/posts?id={post.id}"; say "Update"

proc indexHandler(req: Request) =
  let posts = db.filter(Post)
  req.render:
    html: lang "en"
    head:
      meta: charset "UTF-8"; name "viewport"; content "width=device-width, initial-scale=1"
      script: src "https://unpkg.com/htmx.org@1.6.1"
      title: say "Simple Twitter"
    body:
      tdiv "#posts":
        for post in posts: post.show()
      form:
        tdiv: textarea: placeholder "Write here"; name "content"
        button: hxPost "/posts"; hxTarget "#posts"; hxSwap "beforeend"; say "Add"

proc initPost(req: Request): Post =
  if "id" in req.query: result.id = req.getId()
  let q = req.body.parseSearch()
  result.content = q["content"]

proc createHandler(req: Request) =
  let post = req.initPost()
  db.insert(post)
  req.render: post.show()

proc editHandler(req: Request) =
  let post = db.get(Post, req.getId())
  req.render: post.edit()

proc updateHandler(req: Request) =
  let post = req.initPost()
  db.update(post)
  req.render: post.show()

proc showHandler(req: Request) =
  let post = db.get(Post, req.getId())
  req.render: post.show()

proc deleteHandler(req: Request) =
  db.delete(Post(id: req.getId()))
  req.render: discard

var router: Router
router.get("/", indexHandler)
router.post("/posts", createHandler)
router.get("/posts/edit", editHandler)
router.patch("/posts", updateHandler)
router.get("/posts", showHandler)
router.delete("/posts", deleteHandler)

let server = newServer(router)
echo "Serving on http://localhost:8080"
server.serve(Port(8080))
