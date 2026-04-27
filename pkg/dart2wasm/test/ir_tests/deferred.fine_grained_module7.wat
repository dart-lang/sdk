(module $module7
  (type $#Top <...>)
  (type $BoxedInt <...>)
  (type $JSExternWrapper <...>)
  (type $Object <...>)
  (global $"\")\"" (import "module0" "global4") (ref $JSExternWrapper))
  (global $3 (import "module0" "global18") (ref $BoxedInt))
  (table $module0.cross-module-funcs-0 (import "module0" "cross-module-funcs-0") 45 funcref)
  (global $"\"foo3Code(\"" (ref $JSExternWrapper) <...>)
  (global $FooConst3 (ref $Object)
    (i32.const 111)
    (i32.const 0)
    (struct.new $Object))
  (global $fooGlobal3 (mut (ref null $#Top))
    (ref.null none))
  (elem $module0.cross-module-funcs-0
    (set 14 (ref.func $"foo3Code <noInline>"))
    (set 35 (ref.func $0))
    (set 36 (ref.func $1))
    (set 43 (ref.func $2)))
  (func $"foo3Code <noInline>" (param $var0 (ref null $#Top)) (result (ref null $#Top))
    global.get $FooConst3
    i32.const 18
    call_indirect (param (ref null $#Top)) (result (ref null $#Top))
    drop
    global.get $"\"foo3Code(\""
    local.get $var0
    global.get $"\")\""
    i32.const 19
    call_indirect (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSExternWrapper))
    i32.const 18
    call_indirect (param (ref null $#Top)) (result (ref null $#Top))
    drop
    global.get $3
    global.set $fooGlobal3
    ref.null none
  )
  (func $null (result (ref null $#Top)) <...>)
  (func $null (param $var0 (ref null $#Top)) <...>)
  (func $null (result (ref $Object)) <...>)
)