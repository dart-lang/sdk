(module $M2
  (type $#Top <...>)
  (type $BoxedInt <...>)
  (type $JSExternWrapper <...>)
  (type $Object <...>)
  (global $"\")\"" (import "M" "global3") (ref $JSExternWrapper))
  (table $M.cross-module-funcs-0 (import "M" "cross-module-funcs-0") 45 funcref)
  (global $"\"foo1Code(\"" (ref $JSExternWrapper) <...>)
  (global $1 (ref $BoxedInt) <...>)
  (global $FooConst1 (ref $Object)
    (i32.const 111)
    (i32.const 0)
    (struct.new $Object))
  (global $fooGlobal1 (mut (ref null $#Top))
    (ref.null none))
  (elem $M.cross-module-funcs-0
    (set 3 (ref.func $foo1Code))
    (set 39 (ref.func $0))
    (set 40 (ref.func $1))
    (set 41 (ref.func $2)))
  (func $null (result (ref null $#Top)) <...>)
  (func $null (param $var0 (ref null $#Top)) <...>)
  (func $null (result (ref $Object)) <...>)
  (@binaryen.inline 0)
  (func $foo1Code (param $var0 (ref null $#Top))
    global.get $FooConst1
    i32.const 18
    call_indirect (param (ref null $#Top))
    global.get $"\"foo1Code(\""
    local.get $var0
    global.get $"\")\""
    i32.const 19
    call_indirect (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSExternWrapper))
    i32.const 18
    call_indirect (param (ref null $#Top))
    global.get $1
    global.set $fooGlobal1
  )
)