include karax / prelude
import karax/kajax except fromJson, toJson
import karax/kdom
import json, strformat, tables
import jsony
import sugar
import ../model
var posts: seq[Post]
var content = ""
type PostView = ref object
  editing: bool
  content: kstring

var state = initTable[int64, PostView]()
proc postCreate(status: int, resp: cstring) =
  posts.add(($resp).fromJson(Post))
proc render(post: Post, i: int): VNode =
  var this = state.getOrDefault(post.id, PostView())
  state[post.id] = this
  buildHtml(tdiv(id = $i)):
    if this.editing:
      textarea:
        text this.content
        proc onkeyup(e: Event, n: VNode) =
          this.content = n.value
      button:
        text "Cancel"
        proc onclick() =
          this.content = ""
          this.editing = false
      button:
        text "Update"
        proc onclick() =
          post.text = $this.content
          this.content = ""
          this.editing = false
          ajaxPut(&"/posts", @[], $(%post), (status: int, r: cstring) => (posts[i] = ($r).fromJson(Post)))
    else:
      span: text post.text
      button:
        text "Delete"
        proc onclick(e: Event, n: VNode) =
          ajaxDelete(&"/posts/{post.id}", @[], (status: int, r: cstring) => (posts.delete(i)))
      button:
        text "Edit"
        proc onclick(e: Event, n: VNode) =
          this.editing = true
          this.content = post.text
proc createDom(): VNode =
  buildHtml(tdiv):
    for i, post in posts:
      post.render(i)
    textarea(id="message")
    br()
    button:
      proc onclick() =
        var el = kdom.getElementById("message")
        var body = %Post(text: $el.value)
        el.value = ""
        ajaxPost("/posts", @[], $body, postCreate)
      text "Add"
    tdiv: text content

proc getPosts(status: int, resp: cstring) =
  posts = ($resp).fromJson(seq[Post])

setRenderer createDom

ajaxGet("/posts", @[], getPosts)
