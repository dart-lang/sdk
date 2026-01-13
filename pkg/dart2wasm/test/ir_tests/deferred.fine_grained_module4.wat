(module $module4
  (type $#Top <...>)
  (type $BoxedInt <...>)
  (type $JSStringImpl <...>)
  (type $Object <...>)
  (func $FooConstBase.doit (import "module0" "func14") (param (ref $Object) (ref null $#Top)) (result (ref null $#Top)))
  (func $JSStringImpl._interpolate3 (import "module0" "func10") (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSStringImpl)))
  (func $print (import "module0" "func9") (param (ref null $#Top)) (result (ref null $#Top)))
  (global $".FooConst3(" (import "" "FooConst3(") (ref extern))
  (global $"C427 3" (import "module0" "global11") (ref $BoxedInt))
  (global $"C8 \")\"" (import "module0" "global4") (ref $JSStringImpl))
  (global $"C516 FooConst3" (ref $Object)
    (i32.const 121)
    (i32.const 0)
    (struct.new $Object))
  (global $"C519 \"FooConst3(\"" (ref $JSStringImpl)
    (i32.const 4)
    (i32.const 0)
    (global.get $".FooConst3(")
    (struct.new $JSStringImpl))
  (global $"C527 \"foo3Code(\"" (ref $JSStringImpl) <...>)
  (global $fooGlobal3 (mut (ref null $#Top))
    (ref.null none))
  (func $"foo3Code <noInline>" (param $var0 (ref null $#Top)) (result (ref null $#Top))
    global.get $"C516 FooConst3"
    call $print
    drop
    global.get $"C527 \"foo3Code(\""
    local.get $var0
    global.get $"C8 \")\""
    call $JSStringImpl._interpolate3
    call $print
    drop
    global.get $"C427 3"
    global.set $fooGlobal3
    ref.null none
  )
  (func $FooConst3.doit (param $var0 (ref $Object)) (param $var1 (ref null $#Top)) (result (ref null $#Top))
    global.get $"C519 \"FooConst3(\""
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