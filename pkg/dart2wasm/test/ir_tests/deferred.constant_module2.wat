(module $module2
  (type $#Top <...>)
  (type $Object <...>)
  (type $Array<Object?> <...>)
  (type $JSStringImpl <...>)
  (type $Array<_Type> <...>)
  (type $_FunctionType <...>)
  (type $#ClosureBase <...>)
  (type $#Vtable-0-1 <...>)
  (type $#Closure-0-1 <...>)
  (type $H0 (sub final $Object (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $fun (ref $#Closure-0-1)))))
  (type $#DummyStruct <...>)
  (func $print (import "module0" "func5") (param (ref null $#Top)) (result (ref null $#Top)))
  (global $"C455 _FunctionType" (import "module0" "global7") (ref $_FunctionType))
  (global $S.globalH0Foo (import "S" "globalH0Foo") (ref extern))
  (global $global6 (ref $#Vtable-0-1) <...>)
  (global $global3 (ref $#DummyStruct) <...>)
  (global $"C465 globalH0Foo tear-off" (mut (ref null $#Closure-0-1))
    (ref.null none))
  (global $"C466 H0" (mut (ref null $H0))
    (ref.null none))
  (global $"C467 \"globalH0Foo\"" (ref $JSStringImpl)
    (i32.const 4)
    (i32.const 0)
    (global.get $S.globalH0Foo)
    (struct.new $JSStringImpl))
  (func $globalH0Foo (param $var0 i64) (result (ref null $#Top))
    global.get $"C467 \"globalH0Foo\""
    call $print
  )
  (func $"globalH0Foo tear-off dynamic call entry" (param $var0 (ref $#ClosureBase)) (param $var1 (ref $Array<_Type>)) (param $var2 (ref $Array<Object?>)) (param $var3 (ref $Array<Object?>)) (result (ref null $#Top))
    global.get $"C467 \"globalH0Foo\""
    call $print
  )
  (func $"globalH0Foo tear-off trampoline" (param $var0 (ref struct)) (param $var1 (ref null $#Top)) (result (ref null $#Top))
    global.get $"C467 \"globalH0Foo\""
    call $print
  )
  (func $"C466 H0 (lazy initializer)}" (result (ref $H0))
    (local $var0 (ref $#Closure-0-1))
    (local $var1 (ref $H0))
    i32.const 106
    i32.const 0
    block $label0 (result (ref $#Closure-0-1))
      global.get $"C465 globalH0Foo tear-off"
      br_on_non_null $label0
      i32.const 37
      i32.const 0
      global.get $global3
      global.get $global6
      global.get $"C455 _FunctionType"
      struct.new $#Closure-0-1
      local.tee $var0
      global.set $"C465 globalH0Foo tear-off"
      local.get $var0
    end $label0
    struct.new $H0
    local.tee $var1
    global.set $"C466 H0"
    local.get $var1
  )
)