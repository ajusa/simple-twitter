import strutils, sugar, sequtils
import jester, norm/[model, sqlite], nimja

type Post* = ref object of Model
  text*: string

let db = open(":memory:", "", "", "")
db.createTables(Post())

let BLANK_TWEET_FORM = """
  <form id="newtweet" hx-swap-oob="true">
    <div><textarea placeholder="Write here" name="text"></textarea></div>
    <button hx-post="/posts" hx-target="#posts" hx-swap="beforeend">Add</button>
  </form>"""

proc render(post: Post): string =
  if not post.isNil:
    compileTemplateStr """
    <form hx-target="this">
      <span>{{post.text}}</span>
      <button hx-get="/posts/edit/{{post.id}}">Edit</button>
      <button hx-delete="/posts/{{post.id}}">Delete</button>
    </form>""" 

proc renderEdit(post: Post): string = compileTemplateStr """
  <textarea placeholder="Write here" name="text">{{post.text}}</textarea>
  <button hx-get="/posts/{{post.id}}">Cancel</button>
  <button hx-put="/posts/{{post.id}}">Update</button>""" 

proc index(posts: seq[Post]): string = compileTemplateStr """
  <html lang="en">
    <head>
      <meta charset="UTF-8", name="viewport", content="width=device-width, initial-scale=1">
      <script src="https://unpkg.com/htmx.org@1.6.1"></script>
      <title>Simple Twitter</title>
    </head>
    <body>
      <div id="posts">{{posts.mapIt(it.render).join}}</div>
      {{BLANK_TWEET_FORM}}
    </body>
  </html>"""

proc parsePost(request: Request): Post = 
  result.id = request.params.getOrDefault("id", "0").parseInt
  result.text = request.params.getOrDefault("text", "")

routes:
  get "/": resp @[Post()].dup(db.select("1")).index()
  get "/posts/@id": resp Post().dup(db.select("id = ?", @"id")).render()
  post "/posts":
    resp BLANK_TWEET_FORM & request.parsePost.dup(db.insert).render()
  put "/posts/@id": resp request.parsePost.dup(db.update).render()
  delete "/posts/@id": resp request.parsePost.dup(db.delete).render()
  get "/posts/edit/@id": resp Post().dup(db.select("id = ?", @"id")).renderEdit()
