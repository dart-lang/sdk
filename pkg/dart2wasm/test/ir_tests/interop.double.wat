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
  (func $"dart2wasm._168 (import)" (import "dart2wasm" "_168") (param externref) (result f64))
  (func $"dart2wasm._169 (import)" (import "dart2wasm" "_169") (param f64) (result externref))
  (func $"dart2wasm._295 (import)" (import "dart2wasm" "_295") (param f64) (result externref))
  (func $"dart2wasm._296 (import)" (import "dart2wasm" "_296") (param externref) (result externref))
  (global $"C322 _TopType" (ref $_TopType) <...>)
  (global $"C68 WasmArray<WasmArray<_Type>>[707]" (ref $Array<WasmArray<_Type>>) <...>)
  (global $"doubleValueNullable initialized" (mut i32) <...>)
  (global $doubleValueNullable (mut (ref null $BoxedDouble)) <...>)
  (func $_throwArgumentNullError <noInline>  <...>)
  (func $doubleValue implicit getter (result f64) <...>)
  (func $ktrue implicit getter (result i32) <...>)
  (func $sinkDouble <noInline> (param $var0 f64) <...>)
  (func $sinkDoubleNullable <noInline> (param $var0 (ref null $BoxedDouble)) <...>)
  (func $"testDoubleConstant <noInline>"
    (local $var0 externref)
    f64.const 1.1
    call $"dart2wasm._295 (import)"
    local.tee $var0
    call $isDartNull
    if (result f64)
      call $"_throwArgumentNullError <noInline>"
      unreachable
    else
      local.get $var0
      call $"dart2wasm._168 (import)"
    end
    call $"sinkDouble <noInline>"
  )
  (func $"testDoubleConstantNullable <noInline>"
    (local $var0 externref)
    ref.null noextern
    call $"dart2wasm._296 (import)"
    local.tee $var0
    call $isDartNull
    if (result (ref null $BoxedDouble))
      ref.null none
    else
      i32.const 87
      local.get $var0
      call $"dart2wasm._168 (import)"
      struct.new $BoxedDouble
    end
    call $"sinkDoubleNullable <noInline>"
  )
  (func $"testDoubleValue <noInline>"
    (local $var0 externref)
    call $"doubleValue implicit getter"
    call $"dart2wasm._295 (import)"
    local.tee $var0
    call $isDartNull
    if (result f64)
      call $"_throwArgumentNullError <noInline>"
      unreachable
    else
      local.get $var0
      call $"dart2wasm._168 (import)"
    end
    call $"sinkDouble <noInline>"
  )
  (func $"testDoubleValueNullable <noInline>"
    (local $var0 i32)
    (local $var1 (ref null $BoxedDouble))
    (local $var2 (ref $BoxedDouble))
    (local $var3 (ref $_TopType))
    (local $var4 (ref $Array<_Type>))
    (local $var5 externref)
    global.get $"doubleValueNullable initialized"
    i32.eqz
    if
      call $"ktrue implicit getter"
      if (result (ref null $BoxedDouble))
        i32.const 87
        call $"doubleValue implicit getter"
        struct.new $BoxedDouble
      else
        ref.null none
      end
      global.set $doubleValueNullable
      i32.const 1
      global.set $"doubleValueNullable initialized"
    end
    global.get $doubleValueNullable
    local.tee $var1
    ref.is_null
    if (result externref)
      ref.null noextern
    else
      block $label0 (result externref)
        ref.null noextern
        local.get $var1
        ref.is_null
        br_if $label0
        drop
        block $label1 (result i32)
          i32.const 87
          local.set $var0
          i32.const 1
          local.get $var0
          i32.const 87
          i32.eq
          br_if $label1
          drop
          i32.const 0
        end $label1
        if
          local.get $var1
          struct.get $BoxedDouble $value
          call $"dart2wasm._169 (import)"
          br $label0
        end
        local.get $var1
        ref.as_non_null
        local.set $var2
        local.get $var0
        i32.const 182
        call $_TypeUniverse._checkSubclassRelationshipViaTable
        local.tee $var0
        i32.const -1
        i32.eq
        if (result i32)
          i32.const 0
        else
          global.get $"C322 _TopType"
          local.set $var3
          block $label2 (result i32)
            local.get $var2
            call $Object._typeArguments
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
              br $label2
            end
            global.get $"C68 WasmArray<WasmArray<_Type>>[707]"
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
          end $label2
        end
        if
          unreachable
        else
          local.get $var2
          extern.externalize
          br $label0
        end
        unreachable
      end $label0
    end
    call $"dart2wasm._296 (import)"
    local.tee $var5
    call $isDartNull
    if (result (ref null $BoxedDouble))
      ref.null none
    else
      i32.const 87
      local.get $var5
      call $"dart2wasm._168 (import)"
      struct.new $BoxedDouble
    end
    call $"sinkDoubleNullable <noInline>"
  )
  (func $Object._typeArguments (param $var0 (ref $#Top)) (result (ref $Array<_Type>)) <...>)
  (func $_TypeUniverse._checkSubclassRelationshipViaTable (param $var0 i32) (param $var1 i32) (result i32) <...>)
  (func $_TypeUniverse.isSubtype (param $var0 (ref $_Type)) (param $var1 (ref null $_Environment)) (param $var2 (ref $_Type)) (param $var3 (ref null $_Environment)) (result i32) <...>)
  (func $_TypeUniverse.substituteTypeArgument (param $var0 (ref $_Type)) (param $var1 (ref $Array<_Type>)) (result (ref $_Type)) <...>)
  (func $isDartNull (param $var0 externref) (result i32) <...>)
)