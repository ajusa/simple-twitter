import strutils, mummy, webby, debby/sqlite, rody, xmltree, macros

type Post* = ref object
  id*: int
  content*: string

let db = openDatabase(":memory:")
db.createTable(Post)
db.insert(Post(content: "hello"))

include "template.html"

var handler = route:
  find "/": 
    get:
      resp render(homePage())
  find "/posts":
    var p = Post(content: @"content")
    post:
      db.insert(p)
      redirect "/"
    find int:
      p.id = it
      find "/edit": get:
        resp render(editPostPage(it))
      post:
        db.update(p)
        redirect "/"
      find "/delete": post:
        db.delete(p)
        redirect "/"

echo "Serving on http://localhost:8080"
newServer(handler).serve(Port(8080))
