(module $module1
  (type $#Top <...>)
  (type $BoxedInt <...>)
  (type $JSStringImpl <...>)
  (type $Object <...>)
  (func $"_TypeError._throwNullCheckErrorWithCurrentStack <noInline>" (import "module0" "func0") (result (ref none)))
  (func $Foo1.doitDispatch (import "module0" "func1") (param (ref $Object) (ref null $#Top)) (result (ref null $#Top)))
  (func $JSStringImpl._interpolate3 (import "module0" "func2") (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSStringImpl)))
  (func $print (import "module0" "func3") (param (ref null $#Top)) (result (ref null $#Top)))
  (global $".Foo1.doitDevirt(" (import "" "Foo1.doitDevirt(") (ref extern))
  (global $"C318 1" (import "module0" "global1") (ref $BoxedInt))
  (global $"C347 2" (import "module0" "global3") (ref $BoxedInt))
  (global $"C386 \"FooBase(\"" (import "module0" "global5") (ref $JSStringImpl))
  (global $"C8 \")\"" (import "module0" "global4") (ref $JSStringImpl))
  (global $baseObj (import "module0" "global0") (ref null $Object))
  (global $foo1Obj (import "module0" "global2") (ref null $Object))
  (table $module0.dispatch0 (import "module0" "dispatch0") 773 funcref)
  (global $"C505 \"Foo1.doitDevirt(\"" (ref $JSStringImpl)
    (i32.const 4)
    (i32.const 0)
    (global.get $".Foo1.doitDevirt(")
    (struct.new $JSStringImpl))
  (func $"foo1 <noInline>" (result (ref null $#Top))
    (local $var0 (ref $Object))
    block $label0
      block $label1 (result (ref $Object))
        global.get $baseObj
        br_on_non_null $label1
        br $label0
      end $label1
      local.tee $var0
      global.get $"C318 1"
      local.get $var0
      struct.get $Object $field0
      i32.const 444
      i32.add
      call_indirect $module0.dispatch0 (param (ref $Object) (ref null $#Top)) (result (ref null $#Top))
      drop
      block $label2 (result (ref $Object))
        global.get $foo1Obj
        br_on_non_null $label2
        br $label0
      end $label2
      global.get $"C347 2"
      call $Foo1.doitDispatch
      drop
      block $label3 (result (ref $Object))
        global.get $foo1Obj
        br_on_non_null $label3
        br $label0
      end $label3
      call $Foo1.doitDevirt
      block $label4 (result (ref $Object))
        global.get $foo1Obj
        br_on_non_null $label4
        br $label0
      end $label4
      call $Foo1.doitDevirt
      ref.null none
      return
    end $label0
    call $"_TypeError._throwNullCheckErrorWithCurrentStack <noInline>"
    unreachable
  )
  (func $Foo1.doitDevirt (param $var0 (ref $Object))
    global.get $"C505 \"Foo1.doitDevirt(\""
    global.get $"C318 1"
    global.get $"C8 \")\""
    call $JSStringImpl._interpolate3
    call $print
    drop
    global.get $"C386 \"FooBase(\""
    global.get $"C318 1"
    global.get $"C8 \")\""
    call $JSStringImpl._interpolate3
    call $print
    drop
  )
)