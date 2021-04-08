import jester
import strutils
import jsony
import model
import norm/sqlite
let dbConn = open(":memory:", "", "", "")
dbConn.createTables(Post())

routes:
  get "/posts":
    var posts = @[Post()]
    dbConn.select(posts, "TRUE")
    resp posts.toJson
  post "/posts":
    var post = request.body.fromJson(Post)
    dbConn.insert(post)
    resp post.toJson # return new id
  put "/posts":
    var post = request.body.fromJson(Post)
    dbConn.update(post)
    resp post.toJson # return updated object
  delete "/posts/@id":
    var post = Post(id: @"id".parseInt)
    dbConn.delete(post)
    resp ""
