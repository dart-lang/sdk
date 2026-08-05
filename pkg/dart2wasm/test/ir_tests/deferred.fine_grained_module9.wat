(module $M9
  (type $#Top <...>)
  (type $BoxedInt <...>)
  (type $JSExternWrapper <...>)
  (type $Object <...>)
  (global $"\")\"" (import "M" "global3") (ref $JSExternWrapper))
  (table $M.cross-module-funcs-0 (import "M" "cross-module-funcs-0") 45 funcref)
  (global $"\"foo4Code(\"" (ref $JSExternWrapper) <...>)
  (global $4 (ref $BoxedInt) <...>)
  (global $FooConst4 (ref $Object)
    (i32.const 114)
    (i32.const 0)
    (struct.new $Object))
  (global $fooGlobal4 (mut (ref null $#Top))
    (ref.null none))
  (elem $M.cross-module-funcs-0
    (set 16 (ref.func $foo4Code))
    (set 23 (ref.func $0))
    (set 24 (ref.func $1))
    (set 44 (ref.func $2)))
  (func $null (result (ref null $#Top)) <...>)
  (func $null (param $var0 (ref null $#Top)) <...>)
  (func $null (result (ref $Object)) <...>)
  (@binaryen.inline 0)
  (func $foo4Code (param $var0 (ref null $#Top))
    global.get $FooConst4
    i32.const 18
    call_indirect (param (ref null $#Top))
    global.get $"\"foo4Code(\""
    local.get $var0
    global.get $"\")\""
    i32.const 19
    call_indirect (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSExternWrapper))
    i32.const 18
    call_indirect (param (ref null $#Top))
    global.get $4
    global.set $fooGlobal4
  )
)