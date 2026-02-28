(module $$
  (type $#Top <...>)
  (type $BoxedInt <...>)
  (type $JSExternWrapper <...>)
  (@binaryen.removable.if.unused)
  (func $"wasm:js-string.length (import)" (import "wasm:js-string" "length") (param externref) (result i32))
  (global $"\")\"" (ref $JSExternWrapper) <...>)
  (global $"\"3\"" (ref $JSExternWrapper) <...>)
  (global $"\"4\"" (ref $JSExternWrapper) <...>)
  (global $"\"bar(\"" (ref $JSExternWrapper) <...>)
  (global $"\"foo(\"" (ref $JSExternWrapper) <...>)
  (@binaryen.removable.if.unused)
  (func $"foo <noInline>" (param $var0 (ref $JSExternWrapper)) (result (ref $BoxedInt))
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
    i32.const 113
    local.get $var0
    struct.get $JSExternWrapper $_externRef
    call $"wasm:js-string.length (import)"
    i64.extend_i32_u
    struct.new $BoxedInt
  )
  (func $"runApp <noInline>"
    global.get $"\"3\""
    call $"foo <noInline>"
    call $print
    global.get $"\"4\""
    call $"foo <noInline>"
    call $print
  )
  (func $JSStringImpl._interpolate3 (param $var0 (ref $JSExternWrapper)) (param $var1 (ref $#Top)) (param $var2 (ref $JSExternWrapper)) (result (ref $JSExternWrapper)) <...>)
  (func $print (param $var0 (ref $#Top)) <...>)
)