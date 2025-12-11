(module $module2
  (type $#Top <...>)
  (type $BoxedInt <...>)
  (type $FooConst1 <...>)
  (type $FooConstBase <...>)
  (type $JSStringImpl <...>)
  (func $FooConstBase.doit (import "module0" "func14") (param (ref $FooConstBase) (ref null $#Top)) (result (ref null $#Top)))
  (func $JSStringImpl._interpolate3 (import "module0" "func10") (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSStringImpl)))
  (func $print (import "module0" "func9") (param (ref null $#Top)) (result (ref null $#Top)))
  (global $".FooConst1(" (import "" "FooConst1(") (ref extern))
  (global $"C316 1" (import "module0" "global7") (ref $BoxedInt))
  (global $"C8 \")\"" (import "module0" "global4") (ref $JSStringImpl))
  (global $"C511 FooConst1" (ref $FooConst1)
    (i32.const 117)
    (i32.const 0)
    (struct.new $FooConst1))
  (global $"C518 \"FooConst1(\"" (ref $JSStringImpl)
    (i32.const 4)
    (i32.const 0)
    (global.get $".FooConst1(")
    (struct.new $JSStringImpl))
  (global $"C526 \"foo1Code(\"" (ref $JSStringImpl) <...>)
  (global $fooGlobal1 (mut (ref null $#Top))
    (ref.null none))
  (func $"foo1Code <noInline>" (param $var0 (ref null $#Top)) (result (ref null $#Top))
    global.get $"C511 FooConst1"
    call $print
    drop
    global.get $"C526 \"foo1Code(\""
    local.get $var0
    global.get $"C8 \")\""
    call $JSStringImpl._interpolate3
    call $print
    drop
    global.get $"C316 1"
    global.set $fooGlobal1
    ref.null none
  )
  (func $FooConst1.doit (param $var0 (ref $FooConstBase)) (param $var1 (ref null $#Top)) (result (ref null $#Top))
    (local $var2 (ref $FooConst1))
    local.get $var0
    ref.cast $FooConst1
    global.get $"C518 \"FooConst1(\""
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