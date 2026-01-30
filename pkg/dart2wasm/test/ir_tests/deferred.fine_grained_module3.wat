(module $module3
  (type $#Top <...>)
  (type $BoxedInt <...>)
  (type $JSStringImpl <...>)
  (type $Object <...>)
  (global $".FooConst2(" (import "" "FooConst2(") (ref extern))
  (global $"C353 2" (import "module0" "global12") (ref $BoxedInt))
  (global $"C8 \")\"" (import "module0" "global4") (ref $JSStringImpl))
  (table $module0.cross-module-funcs-0 (import "module0" "cross-module-funcs-0") 34 funcref)
  (global $"C520 FooConst2" (ref $Object)
    (i32.const 123)
    (i32.const 0)
    (struct.new $Object))
  (global $"C525 \"FooConst2(\"" (ref $JSStringImpl)
    (i32.const 4)
    (i32.const 0)
    (global.get $".FooConst2(")
    (struct.new $JSStringImpl))
  (global $"C533 \"foo2Code(\"" (ref $JSStringImpl) <...>)
  (global $fooGlobal2 (mut (ref null $#Top))
    (ref.null none))
  (elem $module0.cross-module-funcs-0
    (set 12 (ref.func $"foo2Code <noInline>"))
    (set 23 (ref.func $"fooGlobal2 implicit getter"))
    (set 31 (ref.func $0)))
  (func $"foo2Code <noInline>" (param $var0 (ref null $#Top)) (result (ref null $#Top))
    global.get $"C520 FooConst2"
    i32.const 18
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    global.get $"C533 \"foo2Code(\""
    local.get $var0
    global.get $"C8 \")\""
    i32.const 19
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSStringImpl))
    i32.const 18
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    global.get $"C353 2"
    global.set $fooGlobal2
    ref.null none
  )
  (func $fooGlobal2 implicit getter (result (ref $#Top)) <...>)
  (func $null (result (ref $Object)) <...>)
  (func $FooConst2.doit (param $var0 (ref $Object)) (param $var1 (ref null $#Top)) (result (ref null $#Top))
    global.get $"C525 \"FooConst2(\""
    local.get $var1
    global.get $"C8 \")\""
    i32.const 19
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSStringImpl))
    i32.const 18
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    local.get $var0
    local.get $var1
    i32.const 27
    call_indirect $module0.cross-module-funcs-0 (param (ref $Object) (ref null $#Top)) (result (ref null $#Top))
    drop
    ref.null none
  )
)