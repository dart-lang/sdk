(module $module2
  (type $#Top <...>)
  (type $BoxedInt <...>)
  (type $JSStringImpl <...>)
  (type $Object <...>)
  (func $FooConstBase.doit (import "module0" "func14") (param (ref $Object) (ref null $#Top)) (result (ref null $#Top)))
  (func $JSStringImpl._interpolate3 (import "module0" "func10") (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSStringImpl)))
  (func $print (import "module0" "func9") (param (ref null $#Top)) (result (ref null $#Top)))
  (global $".FooConst1(" (import "" "FooConst1(") (ref extern))
  (global $"C319 1" (import "module0" "global8") (ref $BoxedInt))
  (global $"C8 \")\"" (import "module0" "global4") (ref $JSStringImpl))
  (global $"C514 FooConst1" (ref $Object)
    (i32.const 119)
    (i32.const 0)
    (struct.new $Object))
  (global $"C521 \"FooConst1(\"" (ref $JSStringImpl)
    (i32.const 4)
    (i32.const 0)
    (global.get $".FooConst1(")
    (struct.new $JSStringImpl))
  (global $"C529 \"foo1Code(\"" (ref $JSStringImpl) <...>)
  (global $fooGlobal1 (mut (ref null $#Top))
    (ref.null none))
  (func $"foo1Code <noInline>" (param $var0 (ref null $#Top)) (result (ref null $#Top))
    global.get $"C514 FooConst1"
    call $print
    drop
    global.get $"C529 \"foo1Code(\""
    local.get $var0
    global.get $"C8 \")\""
    call $JSStringImpl._interpolate3
    call $print
    drop
    global.get $"C319 1"
    global.set $fooGlobal1
    ref.null none
  )
  (func $FooConst1.doit (param $var0 (ref $Object)) (param $var1 (ref null $#Top)) (result (ref null $#Top))
    global.get $"C521 \"FooConst1(\""
    local.get $var1
    global.get $"C8 \")\""
    call $JSStringImpl._interpolate3
    call $print
    drop
    local.get $var0
    local.get $var1
    call $FooConstBase.doit
    drop
    ref.null none
  )
)