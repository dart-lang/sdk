(module $M1
  (type $#Top <...>)
  (type $BoxedInt <...>)
  (type $JSExternWrapper <...>)
  (type $Object <...>)
  (global $".Foo0.doitDispatch(" (import "" "Foo0.doitDispatch(") (ref extern))
  (global $".Foo1.doitDevirt(" (import "" "Foo1.doitDevirt(") (ref extern))
  (global $".Foo1.doitDispatch(" (import "" "Foo1.doitDispatch(") (ref extern))
  (global $".FooBase(" (import "" "FooBase(") (ref extern))
  (global $"\")\"" (import "M" "global2") (ref $JSExternWrapper))
  (table $M.cross-module-funcs-0 (import "M" "cross-module-funcs-0") 18 funcref)
  (table $M.dispatch0 (import "M" "dispatch0") 661 funcref)
  (global $"\"Foo0.doitDispatch(\"" (ref $JSExternWrapper)
    (i32.const 67)
    (i32.const 0)
    (global.get $".Foo0.doitDispatch(")
    (struct.new $JSExternWrapper))
  (global $"\"Foo1.doitDevirt(\"" (ref $JSExternWrapper)
    (i32.const 67)
    (i32.const 0)
    (global.get $".Foo1.doitDevirt(")
    (struct.new $JSExternWrapper))
  (global $"\"Foo1.doitDispatch(\"" (ref $JSExternWrapper)
    (i32.const 67)
    (i32.const 0)
    (global.get $".Foo1.doitDispatch(")
    (struct.new $JSExternWrapper))
  (global $"\"FooBase(\"" (ref $JSExternWrapper)
    (i32.const 67)
    (i32.const 0)
    (global.get $".FooBase(")
    (struct.new $JSExternWrapper))
  (global $1 (ref $BoxedInt) <...>)
  (global $2 (ref $BoxedInt) <...>)
  (global $baseObj (mut (ref null $Object)) <...>)
  (global $foo1Obj (mut (ref null $Object)) <...>)
  (elem $M.cross-module-funcs-0
    (set 0 (ref.func $"runtimeTrue implicit getter"))
    (set 1 (ref.func $foo1))
    (set 2 (ref.func $foo0)))
  (elem $M.dispatch0 <...>)
  (func $runtimeTrue implicit getter (result i32) <...>)
  (func $Foo0.doitDispatch (param $var0 (ref $Object)) (param $var1 (ref null $#Top))
    global.get $"\"Foo0.doitDispatch(\""
    local.get $var1
    global.get $"\")\""
    i32.const 5
    call_indirect $M.cross-module-funcs-0 (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSExternWrapper))
    i32.const 6
    call_indirect $M.cross-module-funcs-0 (param (ref null $#Top))
    local.get $var1
    call $FooBase.doitDispatch
  )
  (func $Foo1 (result (ref $Object)) <...>)
  (func $Foo1.doitDevirt
    global.get $"\"Foo1.doitDevirt(\""
    global.get $1
    global.get $"\")\""
    i32.const 5
    call_indirect $M.cross-module-funcs-0 (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSExternWrapper))
    i32.const 6
    call_indirect $M.cross-module-funcs-0 (param (ref null $#Top))
    global.get $"\"FooBase(\""
    global.get $1
    global.get $"\")\""
    i32.const 5
    call_indirect $M.cross-module-funcs-0 (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSExternWrapper))
    i32.const 6
    call_indirect $M.cross-module-funcs-0 (param (ref null $#Top))
  )
  (func $Foo1.doitDispatch (param $var0 (ref $Object)) (param $var1 (ref null $#Top))
    global.get $"\"Foo1.doitDispatch(\""
    local.get $var1
    global.get $"\")\""
    i32.const 5
    call_indirect $M.cross-module-funcs-0 (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSExternWrapper))
    i32.const 6
    call_indirect $M.cross-module-funcs-0 (param (ref null $#Top))
    local.get $var1
    call $FooBase.doitDispatch
  )
  (func $FooBase.doitDispatch (param $var0 (ref null $#Top))
    global.get $"\"FooBase(\""
    local.get $var0
    global.get $"\")\""
    i32.const 5
    call_indirect $M.cross-module-funcs-0 (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSExternWrapper))
    i32.const 6
    call_indirect $M.cross-module-funcs-0 (param (ref null $#Top))
  )
  (@binaryen.inline 0)
  (func $foo0
    call $"runtimeTrue implicit getter"
    if (result (ref $Object))
      i32.const 110
      i32.const 0
      struct.new $Object
    else
      call $Foo1
    end
    global.set $baseObj
    call $"runtimeTrue implicit getter"
    drop
    call $Foo1
    global.set $foo1Obj
    i64.const 1
    i32.const 3
    call_indirect $M.cross-module-funcs-0 (param i64) (result i32)
    drop
    call $foo1
  )
  (@binaryen.inline 0)
  (func $foo1
    (local $var0 (ref $Object))
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
      i32.const 367
      i32.add
      call_indirect $M.dispatch0 (param (ref $Object) (ref null $#Top))
      block $label2 (result (ref $Object))
        global.get $foo1Obj
        br_on_non_null $label2
        br $label0
      end $label2
      global.get $2
      call $Foo1.doitDispatch
      block $label3 (result (ref $Object))
        global.get $foo1Obj
        br_on_non_null $label3
        br $label0
      end $label3
      drop
      call $Foo1.doitDevirt
      block $label4 (result (ref $Object))
        global.get $foo1Obj
        br_on_non_null $label4
        br $label0
      end $label4
      drop
      call $Foo1.doitDevirt
      return
    end $label0
    i32.const 4
    call_indirect $M.cross-module-funcs-0 
    unreachable
  )
)