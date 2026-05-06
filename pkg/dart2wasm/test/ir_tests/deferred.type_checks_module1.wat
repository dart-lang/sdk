(module $%
  (type $#Top <...>)
  (type $Array<Object?> <...>)
  (type $Array<_Type> <...>)
  (type $Foo <...>)
  (type $JSExternWrapper <...>)
  (type $_Environment <...>)
  (type $_InterfaceType <...>)
  (type $_Type <...>)
  (global $"\")\"_11" (import "$" "2") (ref $JSExternWrapper))
  (global $"\"Attempt to execute code remove<...>\"" (import "$" "(") (ref $JSExternWrapper))
  (global $_InterfaceType (import "$" "0") (ref $_InterfaceType))
  (table $$.% (import "$" "%") 742 funcref)
  (table $$.' (import "$" "'") 20 funcref)
  (global $"\">.takeT(\"" (ref $JSExternWrapper) <...>)
  (global $"\"Foo<\"" (ref $JSExternWrapper) <...>)
  (elem $$.' <...>)
  (elem $$.% <...>)
  (func $"Foo.takeT (body) <noInline>" (param $var0 (ref $Foo)) (param $var1 (ref $#Top))
    (local $var2 (ref $_InterfaceType))
    global.get $"\"Foo<\""
    local.get $var0
    struct.get $Foo $field2
    global.get $"\">.takeT(\""
    local.get $var1
    global.get $"\")\"_11"
    array.new_fixed $Array<Object?> 5
    i32.const 14
    call_indirect $$.' (param (ref $Array<Object?>)) (result (ref $JSExternWrapper))
    i32.const 18
    call_indirect $$.' (param (ref null $#Top))
    global.get $_InterfaceType
    local.set $var2
    block $label0 (result i32)
      i32.const 0
      local.get $var0
      struct.get $Foo $field0
      i32.const 115
      i32.ne
      br_if $label0
      drop
      i32.const 0
      local.get $var0
      local.get $var0
      struct.get $Foo $field0
      i32.const 344
      i32.add
      call_indirect $$.% (param (ref $#Top)) (result (ref $Array<_Type>))
      i32.const 0
      array.get $Array<_Type>
      ref.null none
      local.get $var2
      ref.null none
      i32.const 19
      call_indirect $$.' (param (ref $_Type) (ref null $_Environment) (ref $_Type) (ref null $_Environment)) (result i32)
      i32.const 1
      i32.ne
      br_if $label0
      drop
      i32.const 1
    end $label0
    i32.eqz
    if
      i32.const 2
      call_indirect $$.' 
      unreachable
    end
    local.get $var0
    i32.const 18
    call_indirect $$.' (param (ref null $#Top))
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
            call_indirect $$.' (param (ref $_Type) (ref $#Top)) (result i32)
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
            call_indirect $$.' (param (ref $_Type) (ref $#Top)) (result i32)
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
          call_indirect $$.' (param (ref $_Type) (ref $#Top)) (result i32)
          br $label0
        end
      end $label1
      local.get $var3
      ref.as_non_null
      local.tee $var4
      local.get $var1
      local.get $var4
      struct.get $_Type $field0
      i32.const 467
      i32.add
      call_indirect $$.% (param (ref $_Type) (ref $#Top)) (result i32)
    end $label0
    i32.eqz
    if
      i32.const 2
      call_indirect $$.' 
      global.get $"\"Attempt to execute code remove<...>\""
      i32.const 3
      call_indirect $$.' (param (ref $#Top))
      unreachable
    end
    local.get $var0
    local.get $var1
    call $"Foo.takeT (body) <noInline>"
  )
)