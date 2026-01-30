(module $module2
  (type $#Top <...>)
  (type $BoxedInt <...>)
  (type $JSStringImpl <...>)
  (type $Object <...>)
  (global $".FooConst1(" (import "" "FooConst1(") (ref extern))
  (global $"C324 1" (import "module0" "global8") (ref $BoxedInt))
  (global $"C8 \")\"" (import "module0" "global4") (ref $JSStringImpl))
  (table $module0.cross-module-funcs-0 (import "module0" "cross-module-funcs-0") 34 funcref)
  (global $"C519 FooConst1" (ref $Object)
    (i32.const 122)
    (i32.const 0)
    (struct.new $Object))
  (global $"C526 \"FooConst1(\"" (ref $JSStringImpl)
    (i32.const 4)
    (i32.const 0)
    (global.get $".FooConst1(")
    (struct.new $JSStringImpl))
  (global $"C534 \"foo1Code(\"" (ref $JSStringImpl) <...>)
  (global $fooGlobal1 (mut (ref null $#Top))
    (ref.null none))
  (elem $module0.cross-module-funcs-0
    (set 3 (ref.func $"foo1Code <noInline>"))
    (set 22 (ref.func $"fooGlobal1 implicit getter"))
    (set 30 (ref.func $0)))
  (func $"foo1Code <noInline>" (param $var0 (ref null $#Top)) (result (ref null $#Top))
    global.get $"C519 FooConst1"
    i32.const 18
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    global.get $"C534 \"foo1Code(\""
    local.get $var0
    global.get $"C8 \")\""
    i32.const 19
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSStringImpl))
    i32.const 18
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    global.get $"C324 1"
    global.set $fooGlobal1
    ref.null none
  )
  (func $fooGlobal1 implicit getter (result (ref $#Top)) <...>)
  (func $null (result (ref $Object)) <...>)
  (func $FooConst1.doit (param $var0 (ref $Object)) (param $var1 (ref null $#Top)) (result (ref null $#Top))
    global.get $"C526 \"FooConst1(\""
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