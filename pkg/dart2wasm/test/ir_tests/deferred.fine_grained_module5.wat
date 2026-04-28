(module $module5
  (type $#Top <...>)
  (type $BoxedInt <...>)
  (type $JSExternWrapper <...>)
  (type $Object <...>)
  (global $"\")\"" (import "module0" "global4") (ref $JSExternWrapper))
  (global $2 (import "module0" "global19") (ref $BoxedInt))
  (table $module0.cross-module-funcs-0 (import "module0" "cross-module-funcs-0") 45 funcref)
  (global $"\"foo2Code(\"" (ref $JSExternWrapper) <...>)
  (global $FooConst2 (ref $Object)
    (i32.const 110)
    (i32.const 0)
    (struct.new $Object))
  (global $fooGlobal2 (mut (ref null $#Top))
    (ref.null none))
  (elem $module0.cross-module-funcs-0
    (set 12 (ref.func $"foo2Code <noInline>"))
    (set 37 (ref.func $0))
    (set 38 (ref.func $1))
    (set 42 (ref.func $2)))
  (func $"foo2Code <noInline>" (param $var0 (ref null $#Top))
    global.get $FooConst2
    i32.const 18
    call_indirect (param (ref null $#Top))
    global.get $"\"foo2Code(\""
    local.get $var0
    global.get $"\")\""
    i32.const 19
    call_indirect (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSExternWrapper))
    i32.const 18
    call_indirect (param (ref null $#Top))
    global.get $2
    global.set $fooGlobal2
  )
  (func $null (result (ref null $#Top)) <...>)
  (func $null (param $var0 (ref null $#Top)) <...>)
  (func $null (result (ref $Object)) <...>)
)