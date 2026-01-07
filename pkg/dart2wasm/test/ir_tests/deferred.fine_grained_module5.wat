(module $module5
  (type $#Top <...>)
  (type $BoxedInt <...>)
  (type $FooConst4 <...>)
  (type $FooConstBase <...>)
  (type $JSStringImpl <...>)
  (func $FooConstBase.doit (import "module0" "func14") (param (ref $FooConstBase) (ref null $#Top)) (result (ref null $#Top)))
  (func $JSStringImpl._interpolate3 (import "module0" "func10") (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSStringImpl)))
  (func $print (import "module0" "func9") (param (ref null $#Top)) (result (ref null $#Top)))
  (global $".FooConst4(" (import "" "FooConst4(") (ref extern))
  (global $"C367 4" (import "module0" "global10") (ref $BoxedInt))
  (global $"C8 \")\"" (import "module0" "global4") (ref $JSStringImpl))
  (global $"C517 FooConst4" (ref $FooConst4)
    (i32.const 122)
    (i32.const 0)
    (struct.new $FooConst4))
  (global $"C518 \"FooConst4(\"" (ref $JSStringImpl)
    (i32.const 4)
    (i32.const 0)
    (global.get $".FooConst4(")
    (struct.new $JSStringImpl))
  (global $"C526 \"foo4Code(\"" (ref $JSStringImpl) <...>)
  (global $fooGlobal4 (mut (ref null $#Top))
    (ref.null none))
  (func $"foo4Code <noInline>" (param $var0 (ref null $#Top)) (result (ref null $#Top))
    global.get $"C517 FooConst4"
    call $print
    drop
    global.get $"C526 \"foo4Code(\""
    local.get $var0
    global.get $"C8 \")\""
    call $JSStringImpl._interpolate3
    call $print
    drop
    global.get $"C367 4"
    global.set $fooGlobal4
    ref.null none
  )
  (func $FooConst4.doit (param $var0 (ref $FooConstBase)) (param $var1 (ref null $#Top)) (result (ref null $#Top))
    (local $var2 (ref $FooConst4))
    local.get $var0
    ref.cast $FooConst4
    global.get $"C518 \"FooConst4(\""
    local.get $var1
    global.get $"C8 \")\""
    call $JSStringImpl._interpolate3
    call $print
    drop
    local.get $var1
    call $FooConstBase.doit
    drop
    ref.null none
  )
)