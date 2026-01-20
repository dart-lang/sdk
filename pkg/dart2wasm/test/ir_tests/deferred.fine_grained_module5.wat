(module $module5
  (type $#Top <...>)
  (type $BoxedInt <...>)
  (type $JSStringImpl <...>)
  (type $Object <...>)
  (func $FooConstBase.doit (import "module0" "func14") (param (ref $Object) (ref null $#Top)) (result (ref null $#Top)))
  (func $JSStringImpl._interpolate3 (import "module0" "func10") (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSStringImpl)))
  (func $print (import "module0" "func9") (param (ref null $#Top)) (result (ref null $#Top)))
  (global $".FooConst4(" (import "" "FooConst4(") (ref extern))
  (global $"C372 4" (import "module0" "global10") (ref $BoxedInt))
  (global $"C8 \")\"" (import "module0" "global4") (ref $JSStringImpl))
  (global $"C522 FooConst4" (ref $Object)
    (i32.const 125)
    (i32.const 0)
    (struct.new $Object))
  (global $"C523 \"FooConst4(\"" (ref $JSStringImpl)
    (i32.const 4)
    (i32.const 0)
    (global.get $".FooConst4(")
    (struct.new $JSStringImpl))
  (global $"C531 \"foo4Code(\"" (ref $JSStringImpl) <...>)
  (global $fooGlobal4 (mut (ref null $#Top))
    (ref.null none))
  (func $"foo4Code <noInline>" (param $var0 (ref null $#Top)) (result (ref null $#Top))
    global.get $"C522 FooConst4"
    call $print
    drop
    global.get $"C531 \"foo4Code(\""
    local.get $var0
    global.get $"C8 \")\""
    call $JSStringImpl._interpolate3
    call $print
    drop
    global.get $"C372 4"
    global.set $fooGlobal4
    ref.null none
  )
  (func $FooConst4.doit (param $var0 (ref $Object)) (param $var1 (ref null $#Top)) (result (ref null $#Top))
    global.get $"C523 \"FooConst4(\""
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