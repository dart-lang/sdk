(module $M3
  (type $#Top <...>)
  (type $Array<Object?> <...>)
  (type $BoxedInt <...>)
  (type $JSExternWrapper <...>)
  (type $Object <...>)
  (type $WasmListBase <...>)
  (type $_Future <...>)
  (type $_InterfaceType <...>)
  (type $_Type <...>)
  (global $".FooConst0(" (import "" "FooConst0(") (ref extern))
  (global $".FooConst1(" (import "" "FooConst1(") (ref extern))
  (global $".FooConst2(" (import "" "FooConst2(") (ref extern))
  (global $".FooConst3(" (import "" "FooConst3(") (ref extern))
  (global $".FooConst4(" (import "" "FooConst4(") (ref extern))
  (global $".FooConst5(" (import "" "FooConst5(") (ref extern))
  (global $".FooConstBase(" (import "" "FooConstBase(") (ref extern))
  (global $"\")\"" (import "M" "global3") (ref $JSExternWrapper))
  (global $"\"0\"" (import "M" "global13") (ref $JSExternWrapper))
  (global $"\"[]\"" (import "M" "global4") (ref $JSExternWrapper))
  (global $FooConst0 (import "M" "global5") (ref $Object))
  (global $fooGlobal0 (import "M" "global12") (ref null $#Top))
  (table $M.cross-module-funcs-0 (import "M" "cross-module-funcs-0") 45 funcref)
  (table $M.dispatch0 (import "M" "dispatch0") 677 funcref)
  (global $"\"1\"" (ref $JSExternWrapper) <...>)
  (global $"\"2\"" (ref $JSExternWrapper) <...>)
  (global $"\"3\"" (ref $JSExternWrapper) <...>)
  (global $"\"4\"" (ref $JSExternWrapper) <...>)
  (global $"\"FooConst0(\"" (ref $JSExternWrapper)
    (i32.const 67)
    (i32.const 0)
    (global.get $".FooConst0(")
    (struct.new $JSExternWrapper))
  (global $"\"FooConst1(\"" (ref $JSExternWrapper)
    (i32.const 67)
    (i32.const 0)
    (global.get $".FooConst1(")
    (struct.new $JSExternWrapper))
  (global $"\"FooConst2(\"" (ref $JSExternWrapper)
    (i32.const 67)
    (i32.const 0)
    (global.get $".FooConst2(")
    (struct.new $JSExternWrapper))
  (global $"\"FooConst3(\"" (ref $JSExternWrapper)
    (i32.const 67)
    (i32.const 0)
    (global.get $".FooConst3(")
    (struct.new $JSExternWrapper))
  (global $"\"FooConst4(\"" (ref $JSExternWrapper)
    (i32.const 67)
    (i32.const 0)
    (global.get $".FooConst4(")
    (struct.new $JSExternWrapper))
  (global $"\"FooConst5(\"" (ref $JSExternWrapper)
    (i32.const 67)
    (i32.const 0)
    (global.get $".FooConst5(")
    (struct.new $JSExternWrapper))
  (global $"\"FooConstBase(\"" (ref $JSExternWrapper)
    (i32.const 67)
    (i32.const 0)
    (global.get $".FooConstBase(")
    (struct.new $JSExternWrapper))
  (global $"\"foo5Code(\"" (ref $JSExternWrapper) <...>)
  (global $1 (ref $BoxedInt) <...>)
  (global $5 (ref $BoxedInt) <...>)
  (global $FooConst5 (ref $Object)
    (i32.const 115)
    (i32.const 0)
    (struct.new $Object))
  (global $_InterfaceType (ref $_InterfaceType) <...>)
  (global $allFooConstants (mut (ref null $WasmListBase))
    (ref.null none))
  (global $fooGlobal5 (mut (ref null $#Top))
    (ref.null none))
  (elem $M.cross-module-funcs-0
    (set 17 (ref.func $foo5)))
  (elem $M.dispatch0 <...>)
  (func $fooGlobal5 implicit getter (result (ref $#Top)) <...>)
  (func $FooConst0.doit (param $var0 (ref $Object)) (param $var1 (ref null $#Top))
    global.get $"\"FooConst0(\""
    local.get $var1
    global.get $"\")\""
    i32.const 19
    call_indirect $M.cross-module-funcs-0 (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSExternWrapper))
    i32.const 18
    call_indirect $M.cross-module-funcs-0 (param (ref null $#Top))
    local.get $var1
    call $FooConstBase.doit
  )
  (func $FooConst1.doit (param $var0 (ref $Object)) (param $var1 (ref null $#Top))
    global.get $"\"FooConst1(\""
    local.get $var1
    global.get $"\")\""
    i32.const 19
    call_indirect $M.cross-module-funcs-0 (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSExternWrapper))
    i32.const 18
    call_indirect $M.cross-module-funcs-0 (param (ref null $#Top))
    local.get $var1
    call $FooConstBase.doit
  )
  (func $FooConst2.doit (param $var0 (ref $Object)) (param $var1 (ref null $#Top))
    global.get $"\"FooConst2(\""
    local.get $var1
    global.get $"\")\""
    i32.const 19
    call_indirect $M.cross-module-funcs-0 (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSExternWrapper))
    i32.const 18
    call_indirect $M.cross-module-funcs-0 (param (ref null $#Top))
    local.get $var1
    call $FooConstBase.doit
  )
  (func $FooConst3.doit (param $var0 (ref $Object)) (param $var1 (ref null $#Top))
    global.get $"\"FooConst3(\""
    local.get $var1
    global.get $"\")\""
    i32.const 19
    call_indirect $M.cross-module-funcs-0 (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSExternWrapper))
    i32.const 18
    call_indirect $M.cross-module-funcs-0 (param (ref null $#Top))
    local.get $var1
    call $FooConstBase.doit
  )
  (func $FooConst4.doit (param $var0 (ref $Object)) (param $var1 (ref null $#Top))
    global.get $"\"FooConst4(\""
    local.get $var1
    global.get $"\")\""
    i32.const 19
    call_indirect $M.cross-module-funcs-0 (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSExternWrapper))
    i32.const 18
    call_indirect $M.cross-module-funcs-0 (param (ref null $#Top))
    local.get $var1
    call $FooConstBase.doit
  )
  (func $FooConst5.doit (param $var0 (ref $Object)) (param $var1 (ref null $#Top))
    global.get $"\"FooConst5(\""
    local.get $var1
    global.get $"\")\""
    i32.const 19
    call_indirect $M.cross-module-funcs-0 (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSExternWrapper))
    i32.const 18
    call_indirect $M.cross-module-funcs-0 (param (ref null $#Top))
    local.get $var1
    call $FooConstBase.doit
  )
  (func $FooConstBase.doit (param $var0 (ref null $#Top))
    global.get $"\"FooConstBase(\""
    local.get $var0
    global.get $"\")\""
    i32.const 19
    call_indirect $M.cross-module-funcs-0 (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSExternWrapper))
    i32.const 18
    call_indirect $M.cross-module-funcs-0 (param (ref null $#Top))
  )
  (func $foo5 (result (ref $_Future)) <...>)
  (@binaryen.inline 0)
  (func $foo5Code (param $var0 (ref $#Top))
    (local $var1 (ref $WasmListBase))
    (local $var2 (ref $Object))
    (local $var3 i64)
    global.get $FooConst5
    i32.const 18
    call_indirect $M.cross-module-funcs-0 (param (ref null $#Top))
    global.get $"\"foo5Code(\""
    local.get $var0
    global.get $"\")\""
    i32.const 19
    call_indirect $M.cross-module-funcs-0 (param (ref null $#Top) (ref null $#Top) (ref null $#Top)) (result (ref $JSExternWrapper))
    i32.const 18
    call_indirect $M.cross-module-funcs-0 (param (ref null $#Top))
    global.get $5
    global.set $fooGlobal5
    block $label0 (result (ref $#Top))
      global.get $fooGlobal0
      br_on_non_null $label0
      global.get $1
      global.get $"\"1\""
      global.get $"\"0\""
      call $int.parse
      i64.const 1
      i64.eq
      select (ref $#Top)
      local.tee $var0
      global.set $fooGlobal0
      local.get $var0
    end $label0
    i32.const 20
    call_indirect $M.cross-module-funcs-0 (param (ref null $#Top))
    block $label1 (result (ref $#Top))
      i32.const 39
      call_indirect $M.cross-module-funcs-0 (result (ref null $#Top))
      br_on_non_null $label1
      global.get $1
      global.get $"\"1\""
      global.get $"\"1\""
      call $int.parse
      i64.const 1
      i64.eq
      select (ref $#Top)
      local.tee $var0
      i32.const 40
      call_indirect $M.cross-module-funcs-0 (param (ref null $#Top))
      local.get $var0
    end $label1
    i32.const 3
    call_indirect $M.cross-module-funcs-0 (param (ref null $#Top))
    block $label2 (result (ref $#Top))
      i32.const 37
      call_indirect $M.cross-module-funcs-0 (result (ref null $#Top))
      br_on_non_null $label2
      global.get $1
      global.get $"\"1\""
      global.get $"\"2\""
      call $int.parse
      i64.const 1
      i64.eq
      select (ref $#Top)
      local.tee $var0
      i32.const 38
      call_indirect $M.cross-module-funcs-0 (param (ref null $#Top))
      local.get $var0
    end $label2
    i32.const 12
    call_indirect $M.cross-module-funcs-0 (param (ref null $#Top))
    block $label3 (result (ref $#Top))
      i32.const 35
      call_indirect $M.cross-module-funcs-0 (result (ref null $#Top))
      br_on_non_null $label3
      global.get $1
      global.get $"\"1\""
      global.get $"\"3\""
      call $int.parse
      i64.const 1
      i64.eq
      select (ref $#Top)
      local.tee $var0
      i32.const 36
      call_indirect $M.cross-module-funcs-0 (param (ref null $#Top))
      local.get $var0
    end $label3
    i32.const 14
    call_indirect $M.cross-module-funcs-0 (param (ref null $#Top))
    block $label4 (result (ref $#Top))
      i32.const 23
      call_indirect $M.cross-module-funcs-0 (result (ref null $#Top))
      br_on_non_null $label4
      global.get $1
      global.get $"\"1\""
      global.get $"\"4\""
      call $int.parse
      i64.const 1
      i64.eq
      select (ref $#Top)
      local.tee $var0
      i32.const 24
      call_indirect $M.cross-module-funcs-0 (param (ref null $#Top))
      local.get $var0
    end $label4
    i32.const 16
    call_indirect $M.cross-module-funcs-0 (param (ref null $#Top))
    block $label5 (result (ref $WasmListBase))
      global.get $allFooConstants
      br_on_non_null $label5
      global.get $_InterfaceType
      global.get $FooConst0
      i32.const 41
      call_indirect $M.cross-module-funcs-0 (result (ref $Object))
      i32.const 42
      call_indirect $M.cross-module-funcs-0 (result (ref $Object))
      i32.const 43
      call_indirect $M.cross-module-funcs-0 (result (ref $Object))
      i32.const 44
      call_indirect $M.cross-module-funcs-0 (result (ref $Object))
      global.get $FooConst5
      array.new_fixed $Array<Object?> 6
      i32.const 22
      call_indirect $M.cross-module-funcs-0 (param (ref $_Type) (ref $Array<Object?>)) (result (ref $WasmListBase))
      local.tee $var1
      global.set $allFooConstants
      local.get $var1
    end $label5
    local.tee $var1
    struct.get $WasmListBase $_length
    local.tee $var3
    i64.eqz
    if
      i64.const 0
      local.get $var3
      global.get $"\"[]\""
      i32.const 21
      call_indirect $M.cross-module-funcs-0 (param i64 i64 (ref null $JSExternWrapper))
      unreachable
    end
    local.get $var1
    struct.get $WasmListBase $_data
    i32.const 0
    array.get $Array<Object?>
    ref.cast $Object
    local.tee $var2
    call $"fooGlobal5 implicit getter"
    local.get $var2
    struct.get $Object $field0
    i32.const 421
    i32.add
    call_indirect $M.dispatch0 (param (ref $Object) (ref null $#Top))
  )
  (func $int.parse (param $var0 (ref $JSExternWrapper)) (result i64) <...>)
)