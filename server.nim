import strutils, strformat, sugar, sequtils
import jester, norm/[model, sqlite], karax/[karaxdsl, vdom], dalo

type Post* = ref object of Model
  text*: string

let dbConn = open(":memory:", "", "", "")
dbConn.createTables(Post())

converter toString(x: VNode): string = $x

var tweetField = initField(name = "text", widget = defaultTextarea).attrs(placeholder = "Write here")

proc render(post: Post): VNode =
  buildHtml(tdiv(hx-target="this")):
    span: text post.text
    button(hx-delete = &"/posts/{post.id}"): text "Delete"
    button(hx-get = &"/posts/edit/{post.id}"): text "Edit"

proc renderEdit(post: Post): VNode =
  buildHtml(form(hx-target="this")):
    tweetField.render(post.toValues)
    button(hx-get = &"/posts/{post.id}"): text "Cancel"
    button(hx-put = &"/posts/{post.id}"): text "Update"

proc newTweetForm(): VNode =
  buildHtml(form(id="newtweet", hx-swap-oob="true")):
    tdiv(id="newtweet"): tweetField.render()
    br()
    button(hx-post="/posts", hx-target="#posts", hx-swap="beforeend"): text "Add"

routes:
  get "/":
    var posts = @[Post()].dup dbConn.select("TRUE")
    let html = buildHtml(html(lang = "en")):
      head:
        meta(charset = "UTF-8", name="viewport", content="width=device-width, initial-scale=1")
        script(src = "https://unpkg.com/htmx.org@1.6.1")
        title: text "Simple Twitter"
      body:
        tdiv(id = "posts"):
          for post in posts: post.render()
        newTweetForm()
    resp html
  get "/posts/@id":
    var post = Post().dup dbConn.select("id = ?", @"id")
    resp post.render()
  post "/posts":
    var post = request.params.fromValues(Post)
    dbConn.insert(post)
    resp post.render() & newTweetForm()
  put "/posts/@id":
    var post = request.params.fromValues(Post)
    dbConn.update(post)
    resp post.render()
  delete "/posts/@id":
    var post = request.params.fromValues(Post)
    dbConn.delete(post)
    resp ""
  get "/posts/edit/@id":
    var post = Post().dup dbConn.select("id = ?", @"id")
    resp post.renderEdit()
