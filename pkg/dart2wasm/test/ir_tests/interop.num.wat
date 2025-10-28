(module $module0
  (type $#Top (struct
    (field $field0 i32)))
  (type $_Type (sub $#Top (struct
    (field $field0 i32)
    (field $isDeclaredNullable i32))))
  (type $Array<_Type> (array (field (mut (ref $_Type)))))
  (type $BoxedDouble (sub final $#Top (struct
    (field $field0 i32)
    (field $value f64))))
  (type $_TopType (sub final $_Type (struct
    (field $field0 i32)
    (field $isDeclaredNullable i32))))
  (type $_Environment (struct
    (field $depth i64)))
  (type $Array<WasmArray<_Type>> (array (field (mut (ref $Array<_Type>)))))
  (func $"dart2wasm._274 (import)" (import "dart2wasm" "_274") (param externref) (result externref))
  (func $"dart2wasm._275 (import)" (import "dart2wasm" "_275") (param externref) (result externref))
  (func $"dart2wasm._147 (import)" (import "dart2wasm" "_147") (param externref) (result f64))
  (func $"dart2wasm._148 (import)" (import "dart2wasm" "_148") (param f64) (result externref))
  (global $"C66 WasmArray<WasmArray<_Type>>[766]" (ref $Array<WasmArray<_Type>>) <...>)
  (global $"C313 _TopType" (ref $_TopType) <...>)
  (global $"numValueNullable initialized" (mut i32) <...>)
  (global $numValueNullable (mut (ref null $#Top)) <...>)
  (global $"ktrue initialized" (mut i32) <...>)
  (global $ktrue (mut i32) <...>)
  (global $numValue (mut (ref null $#Top)) <...>)
  (table $dtable2 699 funcref <...>)
  (func $_TypeUniverse.isSubtype (param $var0 (ref $_Type)) (param $var1 (ref null $_Environment)) (param $var2 (ref $_Type)) (param $var3 (ref null $_Environment)) (result i32) <...>)
  (func $_TypeUniverse._checkSubclassRelationshipViaTable (param $var0 i32) (param $var1 i32) (result i32) <...>)
  (func $_TypeUniverse.substituteTypeArgument (param $var0 (ref $_Type)) (param $var1 (ref $Array<_Type>)) (result (ref $_Type)) <...>)
  (func $"testNumConstant <noInline>"
    (local $var0 externref)
    i64.const 1
    call $jsifyInt
    call $"dart2wasm._274 (import)"
    local.tee $var0
    call $isDartNull
    if (result f64)
      call $"_throwArgumentNullError <noInline>"
      unreachable
    else
      local.get $var0
      call $"dart2wasm._147 (import)"
    end
    call $"sinkNum <noInline>"
  )
  (func $"testNumConstantDouble <noInline>"
    (local $var0 externref)
    f64.const 1.1
    call $"dart2wasm._148 (import)"
    call $"dart2wasm._274 (import)"
    local.tee $var0
    call $isDartNull
    if (result f64)
      call $"_throwArgumentNullError <noInline>"
      unreachable
    else
      local.get $var0
      call $"dart2wasm._147 (import)"
    end
    call $"sinkNum <noInline>"
  )
  (func $"testNumConstantNullable <noInline>"
    (local $var0 externref)
    ref.null noextern
    call $"dart2wasm._275 (import)"
    local.tee $var0
    call $isDartNull
    if (result (ref null $BoxedDouble))
      ref.null none
    else
      i32.const 77
      local.get $var0
      call $"dart2wasm._147 (import)"
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
    call $"dart2wasm._274 (import)"
    local.tee $var0
    call $isDartNull
    if (result f64)
      call $"_throwArgumentNullError <noInline>"
      unreachable
    else
      local.get $var0
      call $"dart2wasm._147 (import)"
    end
    call $"sinkNum <noInline>"
  )
  (func $"testNumValueNullable <noInline>"
    (local $var0 i32)
    (local $var1 (ref null $#Top))
    (local $var2 (ref $#Top))
    (local $var3 (ref $_TopType))
    (local $var4 (ref $Array<_Type>))
    (local $var5 externref)
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
    local.tee $var1
    ref.is_null
    if (result externref)
      ref.null noextern
    else
      block $label1 (result externref)
        ref.null noextern
        local.get $var1
        ref.is_null
        br_if $label1
        drop
        block $label2 (result i32)
          i32.const 1
          local.get $var1
          struct.get $#Top $field0
          local.tee $var0
          i32.const 60
          i32.eq
          br_if $label2
          drop
          i32.const 1
          local.get $var0
          i32.const 77
          i32.eq
          br_if $label2
          drop
          i32.const 0
        end $label2
        if
          local.get $var1
          ref.as_non_null
          call $jsifyNum
          br $label1
        end
        local.get $var1
        struct.get $#Top $field0
        i32.const 91
        i32.sub
        local.tee $var0
        i32.const 9
        i32.ge_u
        local.get $var0
        i32.const 10
        i32.ge_u
        i32.and
        if
          local.get $var1
          ref.as_non_null
          local.tee $var2
          struct.get $#Top $field0
          local.tee $var0
          i32.const 170
          i32.eq
          if (result i32)
            i32.const 0
          else
            local.get $var0
            i32.const 170
            call $_TypeUniverse._checkSubclassRelationshipViaTable
          end
          local.tee $var0
          i32.const -1
          i32.eq
          if (result i32)
            i32.const 0
          else
            global.get $"C313 _TopType"
            local.set $var3
            block $label3 (result i32)
              local.get $var2
              local.get $var2
              struct.get $#Top $field0
              i32.const 333
              i32.add
              call_indirect (param (ref $#Top)) (result (ref $Array<_Type>))
              local.set $var4
              local.get $var0
              i32.eqz
              if
                local.get $var4
                i32.const 0
                array.get $Array<_Type>
                ref.null none
                local.get $var3
                ref.null none
                call $_TypeUniverse.isSubtype
                br $label3
              end
              global.get $"C66 WasmArray<WasmArray<_Type>>[766]"
              local.get $var0
              array.get $Array<WasmArray<_Type>>
              i32.const 0
              array.get $Array<_Type>
              local.get $var4
              call $_TypeUniverse.substituteTypeArgument
              ref.null none
              local.get $var3
              ref.null none
              call $_TypeUniverse.isSubtype
            end $label3
          end
          if
            unreachable
          else
            local.get $var2
            struct.get $#Top $field0
            i32.const 90
            i32.eq
            if
              unreachable
            else
              local.get $var2
              extern.externalize
              ref.as_non_null
              br $label1
            end
            unreachable
          end
          unreachable
        end
        ref.null noextern
      end $label1
    end
    call $"dart2wasm._275 (import)"
    local.tee $var5
    call $isDartNull
    if (result (ref null $BoxedDouble))
      ref.null none
    else
      i32.const 77
      local.get $var5
      call $"dart2wasm._147 (import)"
      struct.new $BoxedDouble
    end
    call $"sinkNumNullable <noInline>"
  )
  (func $isDartNull (param $var0 externref) (result i32) <...>)
  (func $sinkNumNullable <noInline> (param $var0 (ref null $BoxedDouble)) <...>)
  (func $jsifyNum (param $var0 (ref $#Top)) (result externref) <...>)
  (func $jsifyInt (param $var0 i64) (result externref) <...>)
  (func $_throwArgumentNullError <noInline>  <...>)
  (func $ktrue implicit getter (result i32) <...>)
  (func $numValue implicit getter (result (ref $#Top)) <...>)
  (func $sinkNum <noInline> (param $var0 f64) <...>)
)