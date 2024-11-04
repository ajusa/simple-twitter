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
  action "/posts/" & $post.id & "/delete"
  tmethod "post"
  span: say post.content & "&nbsp;"
  a: href "/posts/" & $post.id & "/edit"; say "Edit"
  button: say "Delete"

proc edit(post: Post) = 
  form:
    action "/posts/" & $post.id
    tmethod "post"
    post.renderForm()
    a: href "/"; say "Cancel"
    button: say "Update"

proc index(params: PathParams, posts: seq[Post]): string = render:
  let id = params.getOrDefault("id", "-1").parseInt
  html: lang "en"
  head:
    meta: charset "UTF-8"; name "viewport"; content "width=device-width, initial-scale=1"
    script: src "https://unpkg.com/htmx.org@2.0"
    title: say "Simple Twitter"
  body:
    hxBoost "true"
    for post in posts:
      if id >= 0 and post.id == id: post.edit()
      else: post.show()
    form:
      action "/posts"
      tmethod "post"
      renderForm()
      button: say "Add"

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
