(module $M
  (type $#Top <...>)
  (type $BoxedInt <...>)
  (type $JSExternWrapper <...>)
  (func $wasm:js-string.concat (import "wasm:js-string" "concat") (param externref externref) (result (ref extern)))
  (global $".hello " (import "" "hello ") (ref extern))
  (global $.world (import "" "world") (ref extern))
  (func $JSStringImpl.fromRefUnchecked (param $var0 externref) (result (ref $JSExternWrapper)) <...>)
  (@binaryen.inline 0)
  (func $constantStringOps
    i32.const 58
    i64.const 3
    struct.new $BoxedInt
    call $print
    i32.const 58
    i64.const 102
    struct.new $BoxedInt
    call $print
    global.get $".hello "
    call $JSStringImpl.fromRefUnchecked
    struct.get $JSExternWrapper $_externRef
    global.get $.world
    call $wasm:js-string.concat
    call $JSStringImpl.fromRefUnchecked
    call $print
  )
  (func $print (param $var0 (ref $#Top)) <...>)
)