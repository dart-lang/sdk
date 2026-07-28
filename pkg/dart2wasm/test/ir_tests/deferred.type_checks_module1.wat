(module $M1
  (type $#Top <...>)
  (type $Array<Object?> <...>)
  (type $Array<_Type> <...>)
  (type $Foo <...>)
  (type $JSExternWrapper <...>)
  (type $_Environment <...>)
  (type $_InterfaceType <...>)
  (type $_Type <...>)
  (global $"\")\"" (import "M" "0") (ref $JSExternWrapper))
  (global $_InterfaceType (import "M" ".") (ref $_InterfaceType))
  (table $M.$ (import "M" "$") 657 funcref)
  (table $M.& (import "M" "&") 20 funcref)
  (global $"\">.takeT(\"" (ref $JSExternWrapper) <...>)
  (global $"\"Foo<\"" (ref $JSExternWrapper) <...>)
  (elem $M.& <...>)
  (elem $M.$ <...>)
  (@binaryen.inline 0)
  (func $"Foo.takeT (body)" (param $var0 (ref $Foo)) (param $var1 (ref $#Top))
    global.get $"\"Foo<\""
    local.get $var0
    struct.get $Foo $field2
    global.get $"\">.takeT(\""
    local.get $var1
    global.get $"\")\""
    array.new_fixed $Array<Object?> 5
    i32.const 15
    call_indirect $M.& (param (ref $Array<Object?>)) (result (ref $JSExternWrapper))
    i32.const 18
    call_indirect $M.& (param (ref null $#Top))
    block $label0 (result i32)
      i32.const 0
      local.get $var0
      struct.get $Foo $field0
      i32.const 110
      i32.ne
      br_if $label0
      drop
      i32.const 0
      local.get $var0
      local.get $var0
      struct.get $Foo $field0
      i32.const 329
      i32.add
      call_indirect $M.$ (param (ref $#Top)) (result (ref $Array<_Type>))
      i32.const 0
      array.get $Array<_Type>
      ref.null none
      global.get $_InterfaceType
      ref.null none
      i32.const 19
      call_indirect $M.& (param (ref $_Type) (ref null $_Environment) (ref $_Type) (ref null $_Environment)) (result i32)
      i32.const 1
      i32.ne
      br_if $label0
      drop
      i32.const 1
    end $label0
    i32.eqz
    if
      i32.const 2
      call_indirect $M.& 
      unreachable
    end
    local.get $var0
    i32.const 18
    call_indirect $M.& (param (ref null $#Top))
  )
  (func $"Foo.takeT (checked entry)" (param $var0 (ref $Foo)) (param $var1 (ref $#Top))
    (local $var2 i32)
    (local $var3 (ref null $_Type))
    (local $var4 (ref $_Type))
    block $label0 (result i32)
      block $label1
        local.get $var0
        struct.get $Foo $field2
        local.tee $var3
        struct.get $_Type $field0
        local.tee $var2
        i32.const 9
        i32.le_u
        if
          local.get $var2
          i32.const 5
          i32.le_u
          if
            local.get $var2
            i32.const 4
            i32.le_u
            if
              i32.const 0
              local.get $var2
              i32.const 4
              i32.eq
              br_if $label0
              drop
              br $label1
            end
            i32.const 1
            br $label0
          end
          local.get $var2
          i32.const 9
          i32.eq
          if
            local.get $var3
            ref.as_non_null
            local.get $var1
            i32.const 4
            call_indirect $M.& (param (ref $_Type) (ref $#Top)) (result i32)
            br $label0
          end
          br $label1
        end
        local.get $var2
        i32.const 11
        i32.le_u
        if
          local.get $var2
          i32.const 11
          i32.eq
          if
            local.get $var3
            ref.as_non_null
            local.get $var1
            i32.const 5
            call_indirect $M.& (param (ref $_Type) (ref $#Top)) (result i32)
            br $label0
          end
          br $label1
        end
        local.get $var2
        i32.const 13
        i32.eq
        if
          local.get $var3
          ref.as_non_null
          local.get $var1
          i32.const 6
          call_indirect $M.& (param (ref $_Type) (ref $#Top)) (result i32)
          br $label0
        end
      end $label1
      local.get $var3
      ref.as_non_null
      local.tee $var4
      local.get $var1
      local.get $var4
      struct.get $_Type $field0
      i32.const 484
      i32.add
      call_indirect $M.$ (param (ref $_Type) (ref $#Top)) (result i32)
    end $label0
    i32.eqz
    if
      i32.const 2
      call_indirect $M.& 
      unreachable
    end
    local.get $var0
    local.get $var1
    call $"Foo.takeT (body)"
  )
)