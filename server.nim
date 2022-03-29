import strutils, sugar, sequtils
import jester, norm/[model, sqlite], nimja, jsony, helpers

type Post* = ref object of Model
  text*: string

let dbConn = open(":memory:", "", "", "")
dbConn.createTables(Post())

proc byId*(T: typedesc, id: string): T = T().dup dbConn.select("id = ?", id)

proc render(post: Post): string = compileTemplateStr """
  <form hx-target="this">
    <span>{{post.text}}</span>
    <button hx-delete="/posts/{{post.id}}">Delete</button>
    <button hx-get="/posts/edit/{{post.id}}">Edit</button>
  </form>""" 

proc newTweetForm(): string = compileTemplateStr """
  <form id="newtweet" hx-swap-oob="true">
    <div><textarea placeholder="Write here" name="text"></textarea></div>
    <button hx-post="/posts" hx-target="#posts" hx-swap="beforeend">Add</button>
  </form>"""

proc index(posts: seq[Post]): string = compileTemplateStr """
  <html lang="en">
    <head>
      <meta charset="UTF-8", name="viewport", content="width=device-width, initial-scale=1">
      <script src="https://unpkg.com/htmx.org@1.6.1"></script>
      <title>Simple Twitter</title>
    </head>
    <body>
      <div id="posts">{{posts.mapIt(it.render).join}}</div>
      {{newTweetForm()}}
    </body>
  </html>"""

routes:
  get "/": resp (@[Post()].dup dbConn.select("1")).index()
  get "/posts/@id": resp byId(Post, @"id").render()
  post "/posts": grab(post, Post):
    dbConn.insert(post)
    resp post.render() & newTweetForm()
  put "/posts/@id": grab(post, Post):
    dbConn.update(post)
    resp post.render()
  delete "/posts/@id": grab(post, Post):
    dbConn.delete(post)
    resp ""
  get "/posts/edit/@id":
    var post = byId(Post, @"id")
    resp tmpls """
    <textarea placeholder="Write here" name="text">{{post.text}}</textarea>
    <button hx-get="/posts/{{post.id}}">Cancel</button>
    <button hx-put="/posts/{{post.id}}">Update</button>""" 
