import strutils, sugar
import taggy, htmx, rowdy, norm/[model, sqlite], constructor/constructor

type Post* = ref object of Model
  text*: string
let db = open(":memory:", "", "", "")
db.createTables(Post())
proc view(post: Post) = form:
  hxTarget "this"
  hxVars {"id": post.id}
  span: say post.text
  button: hxGet "/getEditPost"; say "Edit"
  button: hxPost "/removePost"; say "Delete"

proc getPost(id: int): string =
  render Post().dup(db.select("id = ?", id)).view()
proc posts(post: Post): string = 
  {.cast(gcsafe).}:
    render: post.dup(db.insert).view()
proc updatePost(post: Post): string =
  {.cast(gcsafe).}:
    render: post.dup(db.update).view()
proc removePost(post: var Post): string =
  {.cast(gcsafe).}: db.delete(post)
proc getEditPost(id: int): string = 
  {.cast(gcsafe).}: render:
    let post = Post().dup(db.select("id = ?", id))
    textarea: placeholder "Write here"; name "text"; say post.text
    button: hxGet "/getPost"; say "Cancel"
    button: hxPost "/updatePost"; say "Update"
var router: Router
router.get(getPost)
router.post(posts)
router.post(updatePost)
router.post(removePost)
router.get(getEditPost)
router.map("GET", "/") do (request: Request) -> string {.gcsafe.}: render: html:
  lang "en"
  head:
    meta: charset "UTF-8"; name "viewport"; attrContent "width=device-width, initial-scale=1"
    script: src "https://unpkg.com/htmx.org@1.6.1"
    script: src "https://unpkg.com/hyperscript.org@0.9.7"
    title: say "Simple Twitter"
  body:
    tdiv "#posts":
      for post in @[Post()].dup(db.select("1")): post.view()
    form:
      hs "on htmx:afterRequest reset() me";
      tdiv: textarea: placeholder "Write here"; name "text"
      button: hxPost "/posts"; hxTarget "#posts"; hxSwap "beforeend"; say "Add"
let server = newServer(router)
echo "Serving on http://localhost:8080"
server.serve(Port(8080))