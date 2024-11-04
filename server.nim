import dekao, dekao/htmx, mummy, mummy/routers, webby, debby/sqlite

type Post* = ref object
  id*: int
  content*: string

let db = openDatabase(":memory:")
db.createTable(Post)
db.insert(Post(content: "hello"))

proc postId(params: PathParams): int = params.getOrDefault("id", "0").parseInt

proc toPost(params: PathParams, body: string): Post =
  Post(id: params.postId(), content: body.parseSearch["content"])

proc renderForm(post = Post()) =
  textarea: placeholder "Write here"; name "content"; say post.content

proc show(post: Post) = form:
  hxTarget "this"
  hxSwap "outerHTML"
  span: say post.content
  button: hxGet "/posts/" & $post.id & "/edit"; say "Edit"
  button: hxDelete "/posts/" & $post.id; say "Delete"

proc edit(post: Post): string = render:
  form:
    hxTarget "this"
    hxSwap "outerHTML"
    post.renderForm()
    button: hxGet "/posts/" & $post.id; say "Cancel"
    button: hxPut "/posts/" & $post.id; say "Update"

proc index(posts: seq[Post]): string = render:
  html: lang "en"
  head:
    meta: charset "UTF-8"; name "viewport"; content "width=device-width, initial-scale=1"
    script: src "https://unpkg.com/htmx.org@1.6.1"
    title: say "Simple Twitter"
  body:
    tdiv "#posts": 
      for post in posts: post.show()
    form:
      tdiv("#newtweet"): renderForm()
      button: hxPost "/posts"; hxTarget "#posts"; hxSwap "beforeend"; say "Add"

proc create(post: Post): string = render:
  post.show()
  tdiv("#newtweet"):
    hxSwapOob "true"
    renderForm()

using req: Request
proc respond(req; resp: string) = req.respond(200, @[("Content-Type", "text/html")], resp)
var router: Router
router.get "/", proc (req) =
  req.respond(db.filter(Post).index())

router.post "/posts", proc (req) = 
  let post = req.pathParams.toPost(req.body)
  db.insert(post)
  req.respond(post.create())

router.get "/posts/@id/edit", proc (req) =
  req.respond(db.get(Post, req.pathParams.postId).edit())

router.put "/posts/@id", proc (req) =
  let post = req.pathParams.toPost(req.body)
  db.update(post)
  req.respond(block: render: post.show())

router.get "/posts/@id", proc (req) =
  req.respond(block: render: db.get(Post, req.pathParams.postId).show())

router.delete "/posts/@id", proc (req) =
  db.delete(Post(id: req.pathParams.postId))
  req.respond("")

echo "Serving on http://localhost:8080"
newServer(router).serve(Port(8080))
