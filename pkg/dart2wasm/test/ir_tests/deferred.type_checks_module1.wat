(module $%
  (type $#Top <...>)
  (type $Array<Object?> <...>)
  (type $Array<_Type> <...>)
  (type $Foo <...>)
  (type $JSStringImpl <...>)
  (type $_Environment <...>)
  (type $_InterfaceType <...>)
  (type $_Type <...>)
  (func $"_throwErrorWithoutDetails <noInline>" (import "$" "'") (result (ref none)))
  (func $JSStringImpl._interpolate (import "$" "<") (param (ref $Array<Object?>)) (result (ref $JSStringImpl)))
  (func $_BottomType._checkInstance (import "$" "*") (param (ref $_Type) (ref $#Top)) (result i32))
  (func $_FunctionType._checkInstance (import "$" "-") (param (ref $_Type) (ref $#Top)) (result i32))
  (func $_InterfaceType._checkInstance (import "$" ",") (param (ref $_Type) (ref $#Top)) (result i32))
  (func $_RecordType._checkInstance (import "$" ".") (param (ref $_Type) (ref $#Top)) (result i32))
  (func $_TopType._checkInstance (import "$" "+") (param (ref $_Type) (ref $#Top)) (result i32))
  (func $_TypeUniverse.isSubtype (import "$" "E") (param (ref $_Type) (ref null $_Environment) (ref $_Type) (ref null $_Environment)) (result i32))
  (func $print (import "$" "D") (param (ref null $#Top)) (result (ref null $#Top)))
  (global $"C15 _InterfaceType" (import "$" "A") (ref $_InterfaceType))
  (global $"C8 \")\"" (import "$" "C") (ref $JSStringImpl))
  (table $$.$ (import "$" "$") 903 funcref)
  (global $"C285 \"Foo<\"" (ref $JSStringImpl) <...>)
  (global $"C286 \">.takeT(\"" (ref $JSStringImpl) <...>)
  (elem $$.$ <...>)
  (func $"Foo.takeT (body) <noInline>" (param $var0 (ref $Foo)) (param $var1 (ref $#Top))
    (local $var2 (ref $_InterfaceType))
    (local $var3 (ref null $Foo))
    global.get $"C285 \"Foo<\""
    local.get $var0
    struct.get $Foo $field2
    global.get $"C286 \">.takeT(\""
    local.get $var1
    global.get $"C8 \")\""
    array.new_fixed $Array<Object?> 5
    call $JSStringImpl._interpolate
    call $print
    drop
    global.get $"C15 _InterfaceType"
    local.set $var2
    block $label0 (result i32)
      i32.const 0
      local.get $var0
      local.tee $var3
      struct.get $Foo $field0
      i32.const 128
      i32.ne
      br_if $label0
      drop
      i32.const 0
      local.get $var0
      local.get $var0
      struct.get $Foo $field0
      i32.const 396
      i32.add
      call_indirect $$.$ (param (ref $#Top)) (result (ref $Array<_Type>))
      i32.const 0
      array.get $Array<_Type>
      ref.null none
      local.get $var2
      ref.null none
      call $_TypeUniverse.isSubtype
      i32.const 1
      i32.ne
      br_if $label0
      drop
      i32.const 1
    end $label0
    i32.eqz
    if
      call $"_throwErrorWithoutDetails <noInline>"
      unreachable
    end
    local.get $var0
    ref.as_non_null
    call $print
    drop
  )
  (func $"Foo.takeT (checked entry)" (param $var0 (ref $Foo)) (param $var1 (ref $#Top))
    (local $var2 (ref null $_Type))
    (local $var3 i32)
    block $label0 (result i32)
      block $label1
        local.get $var0
        struct.get $Foo $field2
        local.tee $var2
        struct.get $_Type $field0
        local.tee $var3
        i32.const 10
        i32.le_u
        if
          local.get $var3
          i32.const 6
          i32.le_u
          if
            local.get $var3
            i32.const 5
            i32.le_u
            if
              local.get $var3
              i32.const 5
              i32.eq
              if
                local.get $var2
                ref.as_non_null
                local.get $var1
                call $_BottomType._checkInstance
                br $label0
              end
              br $label1
            end
            local.get $var2
            ref.as_non_null
            local.get $var1
            call $_TopType._checkInstance
            br $label0
          end
          local.get $var3
          i32.const 10
          i32.eq
          if
            local.get $var2
            ref.as_non_null
            local.get $var1
            call $_InterfaceType._checkInstance
            br $label0
          end
          br $label1
        end
        local.get $var3
        i32.const 12
        i32.le_u
        if
          local.get $var3
          i32.const 12
          i32.eq
          if
            local.get $var2
            ref.as_non_null
            local.get $var1
            call $_FunctionType._checkInstance
            br $label0
          end
          br $label1
        end
        local.get $var3
        i32.const 14
        i32.eq
        if
          local.get $var2
          ref.as_non_null
          local.get $var1
          call $_RecordType._checkInstance
          br $label0
        end
      end $label1
      local.get $var2
      ref.as_non_null
      local.get $var1
      local.get $var2
      struct.get $_Type $field0
      i32.const 573
      i32.add
      call_indirect $$.$ (param (ref $_Type) (ref $#Top)) (result i32)
    end $label0
    i32.eqz
    if
      call $"_throwErrorWithoutDetails <noInline>"
      unreachable
    end
    local.get $var0
    local.get $var1
    call $"Foo.takeT (body) <noInline>"
  )
)