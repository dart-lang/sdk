(module $module1
  (type $#Top <...>)
  (type $BoxedInt <...>)
  (type $Foo1 <...>)
  (type $FooBase <...>)
  (type $JSStringImpl <...>)
  (func $"_TypeError._throwNullCheckErrorWithCurrentStack <noInline>" (import "module0" "func0") (result (ref none)))
  (func $Foo1.doitDispatch (import "module0" "func1") (param (ref $FooBase) (ref null $#Top)) (result (ref null $#Top)))
  (func $JSStringImpl._interpolate3 (import "module0" "func2") (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSStringImpl)))
  (func $print (import "module0" "func3") (param (ref null $#Top)) (result (ref null $#Top)))
  (global $".Foo1.doitDevirt(" (import "" "Foo1.doitDevirt(") (ref extern))
  (global $"C312 1" (import "module0" "global1") (ref $BoxedInt))
  (global $"C341 2" (import "module0" "global3") (ref $BoxedInt))
  (global $"C380 \"FooBase(\"" (import "module0" "global5") (ref $JSStringImpl))
  (global $"C8 \")\"" (import "module0" "global4") (ref $JSStringImpl))
  (global $baseObj (import "module0" "global0") (ref null $FooBase))
  (global $foo1Obj (import "module0" "global2") (ref null $Foo1))
  (table $module0.dispatch0 (import "module0" "dispatch0") 751 funcref)
  (global $"C499 \"Foo1.doitDevirt(\"" (ref $JSStringImpl)
    (i32.const 4)
    (i32.const 0)
    (global.get $".Foo1.doitDevirt(")
    (struct.new $JSStringImpl))
  (func $"foo1 <noInline>" (result (ref null $#Top))
    (local $var0 (ref $FooBase))
    (local $var1 (ref $Foo1))
    (local $var2 (ref $Foo1))
    block $label0
      block $label1 (result (ref $FooBase))
        global.get $baseObj
        br_on_non_null $label1
        br $label0
      end $label1
      local.tee $var0
      global.get $"C312 1"
      local.get $var0
      struct.get $FooBase $field0
      i32.const 476
      i32.add
      call_indirect $module0.dispatch0 (param (ref $FooBase) (ref null $#Top)) (result (ref null $#Top))
      drop
      block $label2 (result (ref $Foo1))
        global.get $foo1Obj
        br_on_non_null $label2
        br $label0
      end $label2
      global.get $"C341 2"
      call $Foo1.doitDispatch
      drop
      block $label3 (result (ref $Foo1))
        global.get $foo1Obj
        br_on_non_null $label3
        br $label0
      end $label3
      local.set $var1
      call $Foo1.doitDevirt
      block $label4 (result (ref $Foo1))
        global.get $foo1Obj
        br_on_non_null $label4
        br $label0
      end $label4
      local.set $var2
      call $Foo1.doitDevirt
      ref.null none
      return
    end $label0
    call $"_TypeError._throwNullCheckErrorWithCurrentStack <noInline>"
    unreachable
  )
  (func $Foo1.doitDevirt
    global.get $"C499 \"Foo1.doitDevirt(\""
    global.get $"C312 1"
    global.get $"C8 \")\""
    call $JSStringImpl._interpolate3
    call $print
    drop
    global.get $"C380 \"FooBase(\""
    global.get $"C312 1"
    global.get $"C8 \")\""
    call $JSStringImpl._interpolate3
    call $print
    drop
  )
)