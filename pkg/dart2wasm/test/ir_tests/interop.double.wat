(module $module0
  (type $#Top (struct (field $field0 i32)))
  (type $_Type (sub $#Top (struct (field $field0 i32) (field $field1 i32))))
  (type $BoxedDouble (sub final $#Top (struct (field $field0 i32) (field $value f64))))
  (type $_TopType (sub final $_Type (struct (field $field0 i32) (field $field1 i32))))
  (func $"dart2wasm._274 (import)"(import "dart2wasm" "_274") (param f64) (result externref))
  (func $"dart2wasm._275 (import)"(import "dart2wasm" "_275") (param externref) (result externref))
  (func $"dart2wasm._147 (import)"(import "dart2wasm" "_147") (param externref) (result f64))
  (func $"dart2wasm._148 (import)"(import "dart2wasm" "_148") (param f64) (result externref))
  (global $"C311 _TopType" (ref $_TopType) (i32.const 6) (i32.const 1) (struct.new $_TopType))
  (global $"doubleValueNullable initialized" (mut i32) (i32.const 0))
  (global $doubleValueNullable (mut (ref null $BoxedDouble)) (ref.null none))
  (global $"ktrue initialized" (mut i32) (i32.const 0))
  (global $ktrue (mut i32) (i32.const 0))
  (global $"doubleValue initialized" (mut i32) (i32.const 0))
  (global $doubleValue (mut f64) (f64.const 0.0))
  (func $_TypeUniverse.isObjectInterfaceSubtype1 (param $var0 (ref $#Top)) (param $var1 i32) (param $var2 (ref $_Type)) (result i32))
  (func $"testDoubleConstant <noInline>"
    (local $var0 externref)
    f64.const 1.1
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
    call $"sinkDouble <noInline>"
  )
  (func $"testDoubleConstantNullable <noInline>"
    (local $var0 externref)
    ref.null noextern
    call $"dart2wasm._275 (import)"
    local.tee $var0
    call $isDartNull
    if (result (ref null $BoxedDouble))
      ref.null none
    else
      i32.const 76
      local.get $var0
      call $"dart2wasm._147 (import)"
      struct.new $BoxedDouble
    end
    call $"sinkDoubleNullable <noInline>"
  )
  (func $"testDoubleValue <noInline>"
    (local $var0 externref)
    global.get $"doubleValue initialized"
    if (result f64)
      global.get $doubleValue
    else
      call $"doubleValue implicit getter"
    end
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
    call $"sinkDouble <noInline>"
  )
  (func $"testDoubleValueNullable <noInline>"
    (local $var0 (ref null $BoxedDouble))
    (local $var1 (ref $BoxedDouble))
    (local $var2 externref)
    (local $var3 i32)
    global.get $"doubleValueNullable initialized"
    i32.eqz
    if
      global.get $"ktrue initialized"
      if (result i32)
        global.get $ktrue
      else
        call $"ktrue implicit getter"
      end
      if (result (ref null $BoxedDouble))
        i32.const 76
        global.get $"doubleValue initialized"
        if (result f64)
          global.get $doubleValue
        else
          call $"doubleValue implicit getter"
        end
        struct.new $BoxedDouble
      else
        ref.null none
      end
      global.set $doubleValueNullable
      i32.const 1
      global.set $"doubleValueNullable initialized"
    end
    global.get $doubleValueNullable
    local.tee $var0
    ref.is_null
    if (result externref)
      ref.null noextern
    else
      block $label0 (result externref)
        ref.null noextern
        local.get $var0
        ref.is_null
        br_if $label0
        drop
        block $label1 (result i32)
          i32.const 1
          i32.const 76
          local.tee $var3
          i32.const 63
          i32.eq
          br_if $label1
          drop
          i32.const 1
          local.get $var3
          i32.const 76
          i32.eq
          br_if $label1
          drop
          i32.const 0
        end $label1
        if
          local.get $var0
          struct.get $BoxedDouble $value
          call $"dart2wasm._148 (import)"
          br $label0
        end
        i32.const -14
        local.tee $var3
        i32.const 9
        i32.ge_u
        local.get $var3
        i32.const 10
        i32.ge_u
        i32.and
        if
          local.get $var0
          ref.as_non_null
          local.tee $var1
          i32.const 167
          global.get $"C311 _TopType"
          call $_TypeUniverse.isObjectInterfaceSubtype1
          if
            unreachable
          else
            local.get $var1
            extern.externalize
            br $label0
          end
          unreachable
        end
        ref.null noextern
      end $label0
    end
    call $"dart2wasm._275 (import)"
    local.tee $var2
    call $isDartNull
    if (result (ref null $BoxedDouble))
      ref.null none
    else
      i32.const 76
      local.get $var2
      call $"dart2wasm._147 (import)"
      struct.new $BoxedDouble
    end
    call $"sinkDoubleNullable <noInline>"
  )
  (func $isDartNull (param $var0 externref) (result i32))
  (func $sinkDoubleNullable <noInline> (param $var0 (ref null $BoxedDouble)))
  (func $_throwArgumentNullError <noInline> )
  (func $ktrue implicit getter (result i32))
  (func $doubleValue implicit getter (result f64))
  (func $sinkDouble <noInline> (param $var0 f64))
)