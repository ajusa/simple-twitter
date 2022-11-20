import strutils, sugar
import taggy, htmx, pigeon, norm/[model, sqlite]

type Post* = ref object of Model
  text*: string

let db = open(":memory:", "", "", "")
db.createTables(Post())

proc blankTweetForm() = form "#newtweet":
  hxSwapOob true
  tdiv: textarea: placeholder "Write here"; name "text"
  button: hxPost "/posts"; hxTarget "#posts"; hxSwap "beforeend"; say "Add"

proc view(post: Post) = form:
  hxTarget "this"
  hxVars {"id": post.id}
  span: say post.text
  button: hxGet "/getEditPost"; say "Edit"
  button: hxPost "/removePost"; say "Delete"

{.push gcsafe.}
autoRoute:
  GET "/"; proc index(): string = render: html:
    let posts = @[Post()].dup(db.select("1"))
    lang "en"
    head:
      meta: charset "UTF-8"; name "viewport"; content "width=device-width, initial-scale=1"
      script: src "https://unpkg.com/htmx.org@1.6.1"
      script: src "https://unpkg.com/htmx.org@1.8.4/dist/ext/json-enc.js"
      title: say "Simple Twitter"
    body:
      hxExt "json-enc"
      tdiv "#posts":
        for post in posts: post.view()
      blankTweetForm()
  proc getPost(id: int): string = render Post().dup(db.select("id = ?", id)).view()
  proc posts(text: string): string = render:
    blankTweetForm(); Post(text: text).dup(db.insert).view()
  proc updatePost(id: int, text: string): string = render:
    Post(id: id, text: text).dup(db.update).view()
  proc removePost(id: int) = discard Post(id: id).dup(db.delete)
  proc getEditPost(id: int): string = render:
    let post = Post().dup(db.select("id = ?", id))
    textarea: placeholder "Write here"; name "text"; say post.text
    button: hxGet "/getPost"; say "Cancel"
    button: hxPost "/updatePost"; say "Update"
{.pop gcsafe.}

run 8080
