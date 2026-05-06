(module $module1
  (type $#Top <...>)
  (type $Array<Object?> <...>)
  (type $ConcurrentModificationError <...>)
  (type $JSExternWrapper <...>)
  (type $Object <...>)
  (type $WasmListBase <...>)
  (type $_Type <...>)
  (table $module0.cross-module-funcs-0 (import "module0" "cross-module-funcs-0") 12 funcref)
  (table $module0.dispatch0 (import "module0" "dispatch0") 666 funcref)
  (elem $module0.cross-module-funcs-0
    (set 0 (ref.func $"runTest <noInline>")))
  (func $"runTest <noInline>"
    (local $var0 (ref $WasmListBase))
    (local $var1 (ref null $#Top))
    (local $var2 (ref $Object))
    (local $var3 (ref $_Type))
    (local $var4 i64)
    (local $var5 i64)
    (local $var6 i64)
    i32.const 1
    call_indirect $module0.cross-module-funcs-0 (result i64)
    local.set $var5
    i32.const 2
    call_indirect $module0.cross-module-funcs-0 (result (ref $WasmListBase))
    local.tee $var0
    struct.get $WasmListBase $field2
    local.set $var3
    local.get $var0
    struct.get $WasmListBase $_length
    local.set $var6
    loop $label0
      block $label1 (result i32)
        local.get $var6
        local.get $var0
        struct.get $WasmListBase $_length
        i64.ne
        if
          local.get $var0
          i32.const 3
          call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top)) (result (ref $ConcurrentModificationError))
          i32.const 4
          call_indirect $module0.cross-module-funcs-0 (param (ref $#Top))
          unreachable
        end
        local.get $var4
        local.get $var6
        i64.ge_s
        if
          ref.null none
          local.set $var1
          i32.const 0
          br $label1
        end
        local.get $var0
        struct.get $WasmListBase $_data
        local.get $var4
        i32.wrap_i64
        array.get $Array<Object?>
        local.set $var1
        local.get $var4
        i64.const 1
        i64.add
        local.set $var4
        i32.const 1
      end $label1
      if
        local.get $var3
        struct.get $_Type $isDeclaredNullable
        i32.const 1
        local.get $var1
        ref.is_null
        select
        i32.eqz
        if
          local.get $var1
          local.get $var3
          i32.const 5
          call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top) (ref $_Type))
        end
        local.get $var1
        ref.cast $Object
        local.tee $var2
        struct.get $Object $field0
        i32.const 109
        i32.eq
        if
          local.get $var2
          local.get $var5
          i32.const 487
          call_indirect $module0.dispatch0 (param (ref $Object) i64)
        else
          local.get $var2
          local.get $var5
          local.get $var2
          struct.get $Object $field0
          i32.const 378
          i32.add
          call_indirect $module0.dispatch0 (param (ref $Object) i64)
        end
        br $label0
      end
    end $label0
    i64.const 0
    i32.const 6
    call_indirect $module0.cross-module-funcs-0 (param i64) (result i32)
    drop
    i32.const 2
    call_indirect $module0.cross-module-funcs-0 (result (ref $WasmListBase))
    i32.const 7
    call_indirect $module0.cross-module-funcs-0 (param (ref $Object)) (result (ref $JSExternWrapper))
    i32.const 8
    call_indirect $module0.cross-module-funcs-0 (param (ref null $#Top))
  )
)