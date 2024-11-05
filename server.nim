import strformat, strutils, sequtils, mummy, mummy/routers, webby, debby/sqlite

type Post* = ref object
  id*: int
  content*: string

let db = openDatabase(":memory:")
db.createTable(Post)
db.insert(Post(content: "hello"))

proc postId(params: PathParams): int = params.getOrDefault("id", "0").parseInt

proc toPost(params: PathParams, body: string): Post =
  Post(id: params.postId(), content: body.parseSearch["content"])

proc renderForm(post = Post()): string =
  &"""<textarea placeholder="Write here" name="content">{post.content}</textarea>"""

proc show(post: Post): string = &"""
<form action="/posts/{post.id}/delete" method="post">
  <span>{post.content}&nbsp;</span>
  <a href="/posts/{post.id}/edit">Edit</a><button>Delete</button>
</form>"""

proc edit(post: Post): string = &"""
<form action="/posts/{post.id}" method="post">
  {post.renderForm()}
  <a href="/">Cancel</a><button>Update</button>
</form>"""

proc index(params: PathParams, posts: seq[Post]): string = 
  let renderedPosts = posts.mapIt(if it.id == params.postId: it.edit() else: it.show()).join
  &"""
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <script src="https://unpkg.com/htmx.org@2.0"></script>
    <title>Simple Twitter</title>
  </head>
  <body hx-boost="true">
    {posts.mapIt(if it.id == params.postId: it.edit() else: it.show()).join}
    <form action="/posts" method="post">
      {renderForm()}
      <button>Add</button>
    </form>
  </body>
</html>"""

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
