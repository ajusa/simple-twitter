import strutils, strformat 
import dekao, dekao/htmx, mummy, mummy/routers, webby, debby/sqlite, nails, nails/dekao_utils

type PostArgs = ref object of RootObj
  content*: string
type Post* = ref object of PostArgs
  id*: int

let db = openDatabase(":memory:")
db.createTable(Post)
db.insert(Post(content: "hello"))

proc fromRequest*(req: Request, posts: var seq[Post]) = posts = db.filter(Post)
proc fromRequest*(req: Request, post: var Post) = post = db.get(Post, req.query["id"].parseInt)

proc form(post: Post) =
  textarea: placeholder "Write here"; name "content"; say post.content

proc show(post: Post) = form:
  hxTarget "this"
  span: say post.content
  button: hxGet &"/posts/edit?id={post.id}"; say "Edit"
  button: hxDelete &"/posts?id={post.id}"; say "Delete"

proc index(req: Request, posts: seq[Post]) =
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
        tdiv("#newtweet"): Post().form()
        button: hxPost "/posts"; hxTarget "#posts"; hxSwap "beforeend"; say "Add"

proc create(req: Request, args: PostArgs) =
  var post = Post(content: args.content)
  db.insert(post)
  req.render:
    post.show()
    tdiv("#newtweet"):
      hxSwapOob "true"
      Post().form()

proc edit(req: Request, post: Post) =
  req.render: form:
    post.form()
    button: hxGet &"/posts?id={post.id}"; say "Cancel"
    button: hxPut &"/posts?id={post.id}"; say "Update"

proc update(req: Request, args: tuple[id: int, postArgs: PostArgs]) =
  var post = Post(id: args.id, content: args.postArgs.content)
  db.update(post)
  req.render: post.show()

proc show(req: Request, post: Post) = req.render: post.show()

proc delete(req: Request, post: Post) =
  db.delete(post)
  req.respond("")

var router: Router
router.get("/", fillArgs(index))
router.post("/posts", fillArgs(create))
router.get("/posts/edit", fillArgs(edit))
router.put("/posts", fillArgs(update))
router.get("/posts", fillArgs(show))
router.delete("/posts", fillArgs(delete))

let server = newServer(router)
echo "Serving on http://localhost:8080"
server.serve(Port(8080))
