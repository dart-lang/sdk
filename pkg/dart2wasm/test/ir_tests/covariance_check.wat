(module $M
  (type $#Top <...>)
  (type $Array<_Type> <...>)
  (type $Callable <...>)
  (type $Fields <...>)
  (type $_FunctionType <...>)
  (type $_InterfaceType <...>)
  (type $_Type <...>)
  (global $_FunctionType (ref $_FunctionType) <...>)
  (global $_InterfaceType (ref $_InterfaceType) <...>)
  (func $"<obj> as Callable<T0>" (param $var0 (ref null $#Top)) (param $var1 (ref $_Type)) (result (ref $Callable))
    (local $var2 (ref null $#Top))
    (local $var3 (ref $_Type))
    (local $var4 i32)
    (local $var5 (ref $#Top))
    (local $var6 (ref $#Top))
    (local $var7 i32)
    (local $var8 i32)
    (local $var9 (ref $Array<_Type>))
    block $label0
      local.get $var0
      local.get $var1
      local.set $var3
      local.set $var2
      block $label1 (result i32)
        block $label2 (result i32)
          block $label3
            local.get $var2
            br_on_null $label3
            local.get $var2
            ref.cast $#Top
            local.set $var5
            local.get $var5
            local.set $var6
            block $label4 (result i32)
              block $label5 (result i32)
                local.get $var6
                struct.get $#Top $field0
                local.set $var8
                block $label6 (result i32)
                  local.get $var8
                  i32.const 108
                  i32.eq
                  if
                    i32.const 1
                    br $label6
                  end
                  i32.const 0
                  br $label6
                end $label6
                br $label5
              end $label5
              br $label4
            end $label4
            local.set $var4
            block $label7
              local.get $var4
              i32.const 1
              i32.eq
              br_if $label7
              i32.const 0
              br $label2
            end $label7
            local.get $var5
            call $Object._getTypeArguments
            local.set $var9
            local.get $var9
            i32.const 0
            array.get $Array<_Type>
            local.get $var3
            call $_isTypeSubtype
            local.set $var4
            block $label8
              local.get $var4
              i32.const 1
              i32.eq
              br_if $label8
              i32.const 0
              br $label2
            end $label8
            i32.const 1
            br $label2
          end $label3
          i32.const 0
        end $label2
        br $label1
      end $label1
      br_if $label0
      local.get $var0
      i32.const 0
      i32.const 108
      local.get $var1
      call $_throwInterfaceTypeAsCheckError1
      unreachable
    end $label0
    local.get $var0
    ref.cast $Callable
    return
  )
  (func $Fields (param $var0 (ref $_Type)) (result (ref $Fields)) <...>)
  (func $Object._getTypeArguments (param $object (ref $#Top)) (result (ref $Array<_Type>)) <...>)
  (func $_isTypeSubtype (param $s (ref $_Type)) (param $t (ref $_Type)) (result i32) <...>)
  (func $_throwInterfaceTypeAsCheckError1 (param $o (ref null $#Top)) (param $isDeclaredNullable i32) (param $tId i32) (param $typeArgument0 (ref $_Type)) <...>)
  (func $covarianceCheckMain
    (local $fields (ref $Fields))
    global.get $_InterfaceType
    call $Fields
    local.set $fields
    local.get $fields
    struct.get $Fields $contravariantUse
    global.get $_FunctionType
    call $"<obj> as Callable<T0>"
    drop
  )
)