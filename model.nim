import norm/model
type
  Post* = ref object of Model
    text*: cstring
