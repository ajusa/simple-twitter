import norm/model
import karax/kbase
type
  Post* = ref object of Model
    text*: kstring
