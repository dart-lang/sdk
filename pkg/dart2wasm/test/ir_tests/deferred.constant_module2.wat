(module $module2
  (type $#Top <...>)
  (type $Object <...>)
  (type $Array<_Type> <...>)
  (type $JSStringImpl <...>)
  (type $Array<_NamedParameter> <...>)
  (type $_FunctionType <...>)
  (type $#Vtable-0-1 <...>)
  (type $#Closure-0-1 <...>)
  (type $H0 (sub final $Object (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $fun (ref $#Closure-0-1)))))
  (type $#DummyStruct <...>)
  (type $_TopType <...>)
  (func $print (import "module0" "func5") (param (ref null $#Top)) (result (ref null $#Top)))
  (global $"C1 WasmArray<_Type>[0]" (import "module0" "global1") (ref $Array<_Type>))
  (global $"C331 _TopType" (import "module0" "global2") (ref $_TopType))
  (global $"C62 WasmArray<_Type>[1]" (import "module0" "global3") (ref $Array<_Type>))
  (global $"C306 WasmArray<_NamedParameter>[0]" (import "module0" "global4") (ref $Array<_NamedParameter>))
  (global $S.globalH0Foo (import "S" "globalH0Foo") (ref extern))
  (table $module0.constant-table0 (import "module0" "constant-table0") 1 (ref null $_FunctionType) <...>)
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
  (func $"globalH0Foo tear-off trampoline" (param $var0 (ref struct)) (param $var1 (ref null $#Top)) (result (ref null $#Top))
    global.get $"C467 \"globalH0Foo\""
    call $print
  )
  (func $"C466 H0 (lazy initializer)}" (result (ref $H0))
    (local $var0 (ref $_FunctionType))
    (local $var1 (ref $#Closure-0-1))
    (local $var2 (ref $H0))
    i32.const 106
    i32.const 0
    block $label0 (result (ref $#Closure-0-1))
      global.get $"C465 globalH0Foo tear-off"
      br_on_non_null $label0
      i32.const 37
      i32.const 0
      global.get $global3
      global.get $global6
      block $label1 (result (ref $_FunctionType))
        i32.const 0
        table.get $module0.constant-table0
        br_on_non_null $label1
        i32.const 0
        i32.const 12
        i32.const 0
        i32.const 0
        i64.const 0
        global.get $"C1 WasmArray<_Type>[0]"
        global.get $"C1 WasmArray<_Type>[0]"
        global.get $"C331 _TopType"
        global.get $"C62 WasmArray<_Type>[1]"
        i64.const 1
        global.get $"C306 WasmArray<_NamedParameter>[0]"
        struct.new $_FunctionType
        local.tee $var0
        table.set $module0.constant-table0
        local.get $var0
      end $label1
      struct.new $#Closure-0-1
      local.tee $var1
      global.set $"C465 globalH0Foo tear-off"
      local.get $var1
    end $label0
    struct.new $H0
    local.tee $var2
    global.set $"C466 H0"
    local.get $var2
  )
)