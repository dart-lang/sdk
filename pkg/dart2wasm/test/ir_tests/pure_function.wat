(module $$
  (type $#Top <...>)
  (type $BoxedInt <...>)
  (type $JSStringImpl <...>)
  (@binaryen.removable.if.unused)
  (func $"wasm:js-string.length (import)" (import "wasm:js-string" "length") (param externref) (result i32))
  (global $"\")\"" (ref $JSStringImpl) <...>)
  (global $"\"3\"" (ref $JSStringImpl) <...>)
  (global $"\"4\"" (ref $JSStringImpl) <...>)
  (global $"\"bar(\"" (ref $JSStringImpl) <...>)
  (global $"\"foo(\"" (ref $JSStringImpl) <...>)
  (@binaryen.removable.if.unused)
  (func $"foo <noInline>" (param $var0 (ref $JSStringImpl)) (result (ref $BoxedInt))
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
    i32.const 69
    local.get $var0
    struct.get $JSStringImpl $_ref
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
  (func $JSStringImpl._interpolate3 (param $var0 (ref $JSStringImpl)) (param $var1 (ref $#Top)) (param $var2 (ref $JSStringImpl)) (result (ref $JSStringImpl)) <...>)
  (func $print (param $var0 (ref $#Top)) <...>)
)