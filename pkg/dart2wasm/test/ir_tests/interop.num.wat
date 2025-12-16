(module $module0
  (type $#Top (struct
    (field $field0 i32)))
  (type $Array<WasmArray<_Type>> (array (field (mut (ref $Array<_Type>)))))
  (type $Array<_Type> (array (field (mut (ref $_Type)))))
  (type $BoxedDouble (sub final $#Top (struct
    (field $field0 i32)
    (field $value f64))))
  (type $_Environment (struct
    (field $depth i64)))
  (type $_TopType (sub final $_Type (struct
    (field $field0 i32)
    (field $isDeclaredNullable i32))))
  (type $_Type (sub $#Top (struct
    (field $field0 i32)
    (field $isDeclaredNullable i32))))
  (func $"dart2wasm._167 (import)" (import "dart2wasm" "_167") (param externref) (result f64))
  (func $"dart2wasm._168 (import)" (import "dart2wasm" "_168") (param f64) (result externref))
  (func $"dart2wasm._294 (import)" (import "dart2wasm" "_294") (param externref) (result externref))
  (func $"dart2wasm._295 (import)" (import "dart2wasm" "_295") (param externref) (result externref))
  (table $dtable0 745 funcref)
  (global $"C319 _TopType" (ref $_TopType) <...>)
  (global $"C66 WasmArray<WasmArray<_Type>>[729]" (ref $Array<WasmArray<_Type>>) <...>)
  (global $"ktrue initialized" (mut i32) <...>)
  (global $"numValueNullable initialized" (mut i32) <...>)
  (global $ktrue (mut i32) <...>)
  (global $numValue (mut (ref null $#Top)) <...>)
  (global $numValueNullable (mut (ref null $#Top)) <...>)
  (elem $dtable0 <...>)
  (func $_throwArgumentNullError <noInline>  <...>)
  (func $ktrue implicit getter (result i32) <...>)
  (func $numValue implicit getter (result (ref $#Top)) <...>)
  (func $sinkNum <noInline> (param $var0 f64) <...>)
  (func $sinkNumNullable <noInline> (param $var0 (ref null $BoxedDouble)) <...>)
  (func $"testNumConstant <noInline>"
    (local $var0 externref)
    i64.const 1
    call $jsifyInt
    call $"dart2wasm._294 (import)"
    local.tee $var0
    call $isDartNull
    if (result f64)
      call $"_throwArgumentNullError <noInline>"
      unreachable
    else
      local.get $var0
      call $"dart2wasm._167 (import)"
    end
    call $"sinkNum <noInline>"
  )
  (func $"testNumConstantDouble <noInline>"
    (local $var0 externref)
    f64.const 1.1
    call $"dart2wasm._168 (import)"
    call $"dart2wasm._294 (import)"
    local.tee $var0
    call $isDartNull
    if (result f64)
      call $"_throwArgumentNullError <noInline>"
      unreachable
    else
      local.get $var0
      call $"dart2wasm._167 (import)"
    end
    call $"sinkNum <noInline>"
  )
  (func $"testNumConstantNullable <noInline>"
    (local $var0 externref)
    ref.null noextern
    call $"dart2wasm._295 (import)"
    local.tee $var0
    call $isDartNull
    if (result (ref null $BoxedDouble))
      ref.null none
    else
      i32.const 84
      local.get $var0
      call $"dart2wasm._167 (import)"
      struct.new $BoxedDouble
    end
    call $"sinkNumNullable <noInline>"
  )
  (func $"testNumValue <noInline>"
    (local $var0 externref)
    block $label0 (result (ref $#Top))
      global.get $numValue
      br_on_non_null $label0
      call $"numValue implicit getter"
    end $label0
    call $jsifyNum
    call $"dart2wasm._294 (import)"
    local.tee $var0
    call $isDartNull
    if (result f64)
      call $"_throwArgumentNullError <noInline>"
      unreachable
    else
      local.get $var0
      call $"dart2wasm._167 (import)"
    end
    call $"sinkNum <noInline>"
  )
  (func $"testNumValueNullable <noInline>"
    (local $var0 (ref null $#Top))
    (local $var1 (ref $#Top))
    (local $var2 (ref $_TopType))
    (local $var3 (ref $Array<_Type>))
    (local $var4 externref)
    (local $var5 i32)
    global.get $"numValueNullable initialized"
    i32.eqz
    if
      global.get $"ktrue initialized"
      if (result i32)
        global.get $ktrue
      else
        call $"ktrue implicit getter"
      end
      if (result (ref null $#Top))
        block $label0 (result (ref $#Top))
          global.get $numValue
          br_on_non_null $label0
          call $"numValue implicit getter"
        end $label0
      else
        ref.null none
      end
      global.set $numValueNullable
      i32.const 1
      global.set $"numValueNullable initialized"
    end
    global.get $numValueNullable
    local.tee $var0
    ref.is_null
    if (result externref)
      ref.null noextern
    else
      block $label1 (result externref)
        ref.null noextern
        local.get $var0
        ref.is_null
        br_if $label1
        drop
        block $label2 (result i32)
          i32.const 1
          local.get $var0
          struct.get $#Top $field0
          local.tee $var5
          i32.const 65
          i32.eq
          br_if $label2
          drop
          i32.const 1
          local.get $var5
          i32.const 84
          i32.eq
          br_if $label2
          drop
          i32.const 0
        end $label2
        if
          local.get $var0
          ref.as_non_null
          call $jsifyNum
          br $label1
        end
        local.get $var0
        struct.get $#Top $field0
        i32.const 86
        i32.sub
        i32.const 10
        i32.ge_u
        if
          block $label3 (result i32)
            i32.const 1
            local.get $var0
            struct.get $#Top $field0
            local.tee $var5
            i32.const 70
            i32.eq
            br_if $label3
            drop
            i32.const 1
            local.get $var5
            i32.const 86
            i32.sub
            i32.const 10
            i32.lt_u
            br_if $label3
            drop
            i32.const 0
          end $label3
          i32.eqz
          if
            local.get $var0
            ref.as_non_null
            local.tee $var1
            struct.get $#Top $field0
            local.tee $var5
            i32.const 180
            i32.eq
            if (result i32)
              i32.const 0
            else
              local.get $var5
              i32.const 180
              call $_TypeUniverse._checkSubclassRelationshipViaTable
            end
            local.tee $var5
            i32.const -1
            i32.eq
            if (result i32)
              i32.const 0
            else
              global.get $"C319 _TopType"
              local.set $var2
              block $label4 (result i32)
                local.get $var1
                local.get $var1
                struct.get $#Top $field0
                i32.const 354
                i32.add
                call_indirect (param (ref $#Top)) (result (ref $Array<_Type>))
                local.set $var3
                local.get $var5
                i32.eqz
                if
                  local.get $var3
                  i32.const 0
                  array.get $Array<_Type>
                  ref.null none
                  local.get $var2
                  ref.null none
                  call $_TypeUniverse.isSubtype
                  br $label4
                end
                global.get $"C66 WasmArray<WasmArray<_Type>>[729]"
                local.get $var5
                array.get $Array<WasmArray<_Type>>
                i32.const 0
                array.get $Array<_Type>
                local.get $var3
                call $_TypeUniverse.substituteTypeArgument
                ref.null none
                local.get $var2
                ref.null none
                call $_TypeUniverse.isSubtype
              end $label4
            end
            if
              unreachable
            else
              local.get $var1
              struct.get $#Top $field0
              i32.const 64
              i32.eq
              if
                unreachable
              else
                local.get $var1
                extern.externalize
                ref.as_non_null
                br $label1
              end
              unreachable
            end
            unreachable
          end
        end
        ref.null noextern
      end $label1
    end
    call $"dart2wasm._295 (import)"
    local.tee $var4
    call $isDartNull
    if (result (ref null $BoxedDouble))
      ref.null none
    else
      i32.const 84
      local.get $var4
      call $"dart2wasm._167 (import)"
      struct.new $BoxedDouble
    end
    call $"sinkNumNullable <noInline>"
  )
  (func $_TypeUniverse._checkSubclassRelationshipViaTable (param $var0 i32) (param $var1 i32) (result i32) <...>)
  (func $_TypeUniverse.isSubtype (param $var0 (ref $_Type)) (param $var1 (ref null $_Environment)) (param $var2 (ref $_Type)) (param $var3 (ref null $_Environment)) (result i32) <...>)
  (func $_TypeUniverse.substituteTypeArgument (param $var0 (ref $_Type)) (param $var1 (ref $Array<_Type>)) (result (ref $_Type)) <...>)
  (func $isDartNull (param $var0 externref) (result i32) <...>)
  (func $jsifyInt (param $var0 i64) (result externref) <...>)
  (func $jsifyNum (param $var0 (ref $#Top)) (result externref) <...>)
)