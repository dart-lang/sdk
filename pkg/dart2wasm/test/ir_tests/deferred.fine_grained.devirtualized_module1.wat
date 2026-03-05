(module $module1
  (type $#Top <...>)
  (type $BoxedInt <...>)
  (type $JSExternWrapper <...>)
  (type $Object <...>)
  (global $".Foo0.doitDispatch(" (import "" "Foo0.doitDispatch(") (ref extern))
  (global $".Foo1.doitDevirt(" (import "" "Foo1.doitDevirt(") (ref extern))
  (global $".Foo1.doitDispatch(" (import "" "Foo1.doitDispatch(") (ref extern))
  (global $".FooBase(" (import "" "FooBase(") (ref extern))
  (global $"\")\"" (import "module0" "global4") (ref $JSExternWrapper))
  (global $1 (import "module0" "global1") (ref $BoxedInt))
  (global $2 (import "module0" "global3") (ref $BoxedInt))
  (global $baseObj (import "module0" "global0") (ref null $Object))
  (global $foo1Obj (import "module0" "global2") (ref null $Object))
  (table $module0.cross-module-funcs-0 (import "module0" "cross-module-funcs-0") 4 funcref)
  (table $module0.dispatch0 (import "module0" "dispatch0") 678 funcref)
  (global $"\"Foo0.doitDispatch(\"" (ref $JSExternWrapper)
    (i32.const 108)
    (i32.const 0)
    (global.get $".Foo0.doitDispatch(")
    (struct.new $JSExternWrapper))
  (global $"\"Foo1.doitDevirt(\"" (ref $JSExternWrapper)
    (i32.const 108)
    (i32.const 0)
    (global.get $".Foo1.doitDevirt(")
    (struct.new $JSExternWrapper))
  (global $"\"Foo1.doitDispatch(\"" (ref $JSExternWrapper)
    (i32.const 108)
    (i32.const 0)
    (global.get $".Foo1.doitDispatch(")
    (struct.new $JSExternWrapper))
  (global $"\"FooBase(\"" (ref $JSExternWrapper)
    (i32.const 108)
    (i32.const 0)
    (global.get $".FooBase(")
    (struct.new $JSExternWrapper))
  (elem $module0.dispatch0 <...>)
  (elem $module0.cross-module-funcs-0
    (set 0 (ref.func $"foo1 <noInline>")))
  (func $"foo1 <noInline>" (result (ref null $#Top))
    (local $var0 (ref $Object))
    (local $var1 (ref $Object))
    (local $var2 (ref $Object))
    block $label0
      block $label1 (result (ref $Object))
        global.get $baseObj
        br_on_non_null $label1
        br $label0
      end $label1
      local.tee $var0
      global.get $1
      local.get $var0
      struct.get $Object $field0
      i32.const 452
      i32.add
      call_indirect $module0.dispatch0 (param (ref $Object) (ref null $#Top)) (result (ref null $#Top))
      drop
      block $label2 (result (ref $Object))
        global.get $foo1Obj
        br_on_non_null $label2
        br $label0
      end $label2
      global.get $2
      call $Foo1.doitDispatch
      drop
      block $label3 (result (ref $Object))
        global.get $foo1Obj
        br_on_non_null $label3
        br $label0
      end $label3
      local.set $var1
      call $Foo1.doitDevirt
      block $label4 (result (ref $Object))
        global.get $foo1Obj
        br_on_non_null $label4
        br $label0
      end $label4
      local.set $var2
      call $Foo1.doitDevirt
      ref.null none
      return
    end $label0
    i32.const 1
    call_indirect $module0.cross-module-funcs-0 (result (ref none))
    unreachable
  )
  (func $Foo0.doitDispatch (param $var0 (ref $Object)) (param $var1 (ref null $#Top)) (result (ref null $#Top))
    global.get $"\"Foo0.doitDispatch(\""
    local.get $var1
    global.get $"\")\""
    i32.const 2
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSExternWrapper))
    i32.const 3
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    local.get $var1
    call $FooBase.doitDispatch
    ref.null none
  )
  (func $Foo1.doitDevirt
    global.get $"\"Foo1.doitDevirt(\""
    global.get $1
    global.get $"\")\""
    i32.const 2
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSExternWrapper))
    i32.const 3
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    global.get $"\"FooBase(\""
    global.get $1
    global.get $"\")\""
    i32.const 2
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSExternWrapper))
    i32.const 3
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
  )
  (func $Foo1.doitDispatch (param $var0 (ref $Object)) (param $var1 (ref null $#Top)) (result (ref null $#Top))
    global.get $"\"Foo1.doitDispatch(\""
    local.get $var1
    global.get $"\")\""
    i32.const 2
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSExternWrapper))
    i32.const 3
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
    local.get $var1
    call $FooBase.doitDispatch
    ref.null none
  )
  (func $FooBase.doitDispatch (param $var0 (ref null $#Top))
    global.get $"\"FooBase(\""
    local.get $var0
    global.get $"\")\""
    i32.const 2
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSExternWrapper))
    i32.const 3
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref null $#Top))
    drop
  )
)