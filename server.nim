import strutils, mummy, webby, debby/sqlite, rody

type Post* = ref object
  id*: int
  content*: string

let db = openDatabase(":memory:")
db.createTable(Post)
db.insert(Post(content: "hello"))

include "template.html"

let handler = route:
  headers["Content-Type"] = "text/html"
  at "/": 
    get:
      resp render(homePage())
  at "/posts":
    var newPost = Post(content: @"content")
    post:
      db.insert(newPost)
      redirect "/"
    at int:
      var p = db.get(Post, it)
      at "/edit": get:
        resp render(p.editPage())
      post:
        newPost.id = it
        db.update(newPost)
        redirect "/"
      at "/delete": post:
        db.delete(p)
        redirect "/"

echo "Serving on http://localhost:8080"
newServer(handler).serve(Port(8080))
