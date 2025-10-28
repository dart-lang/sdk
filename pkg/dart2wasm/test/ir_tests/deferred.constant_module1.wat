(module $module1
  (type $#Top <...>)
  (type $Object <...>)
  (type $JSStringImpl <...>)
  (type $Array<Object?> <...>)
  (type $_Type <...>)
  (type $type9 <...>)
  (type $#Vtable-0-1 <...>)
  (type $#Closure-0-1 <...>)
  (type $H1 (sub final $Object (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $fun (ref $#Closure-0-1)))))
  (type $BoxedInt <...>)
  (func $"C380 H1 (lazy initializer)}" (import "module0" "func0") (result (ref $H1)))
  (func $print (import "module0" "func1") (param (ref null $#Top)) (result (ref null $#Top)))
  (func $JSStringImpl._interpolate (import "module0" "func2") (param (ref $Array<Object?>)) (result (ref $JSStringImpl)))
  (global $module0.global0 (import "module0" "global0") (ref null $H1))
  (global $module0.global1 (import "module0" "global1") (ref $JSStringImpl))
  (global $module0.global2 (import "module0" "global2") (ref $JSStringImpl))
  (global $module0.global3 (import "module0" "global3") (ref $JSStringImpl))
  (func $"modH1UseH1 <noInline>" (result (ref null $#Top))
    (local $var0 (ref $#Closure-0-1))
    block $label0 (result (ref $H1))
      global.get $module0.global0
      br_on_non_null $label0
      call $"C380 H1 (lazy initializer)}"
    end $label0
    call $print
    drop
    block $label1 (result (ref $H1))
      global.get $module0.global0
      br_on_non_null $label1
      call $"C380 H1 (lazy initializer)}"
    end $label1
    struct.get $H1 $fun
    local.tee $var0
    struct.get $#Closure-0-1 $context
    i32.const 84
    i64.const 1
    struct.new $BoxedInt
    local.get $var0
    struct.get $#Closure-0-1 $vtable
    struct.get $#Vtable-0-1 $closureCallEntry-0-1
    call_ref $type9
    drop
    ref.null none
  )
  (func $globalH1Foo (param $var0 (ref $_Type)) (param $var1 (ref null $#Top)) (result (ref null $#Top))
    global.get $module0.global1
    local.get $var0
    global.get $module0.global2
    local.get $var1
    global.get $module0.global3
    array.new_fixed $Array<Object?> 5
    call $JSStringImpl._interpolate
    call $print
  )
)