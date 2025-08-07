import strutils, mummy, mummy/routers, webby, debby/sqlite, rowdy

type Post* = ref object
  id*: int
  content*: string

let db = openDatabase(":memory:")
db.createTable(Post)
db.insert(Post(content: "hello"))

proc homePage(post: Post): string {.gcsafe.}

proc createPostHandler(request: Request, post: Post) =
  db.insert(post)
  request.redirect(homePage.link)

proc updatePostHandler(request: Request, id: int, post: Post) =
  post.id = id
  db.update(post)
  request.redirect(homePage.link)

proc deletePostHandler(request: Request, id: int) =
  db.delete(Post(id: id))
  request.redirect(homePage.link)

include "template.html"

var router: Router
router.get "/", homePage
router.get "/posts/@id/edit", editPostPage
router.post "/", createPostHandler
router.post "/posts/@id", updatePostHandler
router.post "/posts/@id/delete", deletePostHandler

echo "Serving on http://localhost:8080"
newServer(router).serve(Port(8080))