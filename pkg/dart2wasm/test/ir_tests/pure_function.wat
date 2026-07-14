(module $M
  (type $#Top <...>)
  (type $BoxedInt <...>)
  (type $JSExternWrapper <...>)
  (func $wasm:js-string.length (import "wasm:js-string" "length") (param externref) (result i32))
  (global $"\")\"" (ref $JSExternWrapper) <...>)
  (global $"\"3\"" (ref $JSExternWrapper) <...>)
  (global $"\"4\"" (ref $JSExternWrapper) <...>)
  (global $"\"bar(\"" (ref $JSExternWrapper) <...>)
  (global $"\"foo(\"" (ref $JSExternWrapper) <...>)
  (func $JSStringImpl._interpolate3 (param $var0 (ref $JSExternWrapper)) (param $var1 (ref $#Top)) (param $var2 (ref $JSExternWrapper)) (result (ref $JSExternWrapper)) <...>)
  (@binaryen.removable.if.unused)
  (@binaryen.inline 0)
  (func $foo (param $var0 (ref $JSExternWrapper)) (result (ref $BoxedInt))
    global.get $"\"foo(\""
    local.get $var0
    global.get $"\")\""
    call $JSStringImpl._interpolate3
    drop
    global.get $"\"bar(\""
    local.get $var0
    global.get $"\")\""
    call $JSStringImpl._interpolate3
    drop
    i32.const 58
    local.get $var0
    struct.get $JSExternWrapper $_externRef
    call $wasm:js-string.length
    i64.extend_i32_u
    struct.new $BoxedInt
  )
  (func $print (param $var0 (ref $#Top)) <...>)
  (@binaryen.inline 0)
  (func $runApp
    global.get $"\"3\""
    call $foo
    call $print
    global.get $"\"4\""
    call $foo
    call $print
  )
)