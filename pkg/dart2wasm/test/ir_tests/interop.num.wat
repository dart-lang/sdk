(module $module0
  (type $#Top (struct (field $field0 i32)))
  (type $_Type (sub $#Top (struct (field $field0 i32) (field $field1 i32))))
  (type $BoxedDouble (sub final $#Top (struct (field $field0 i32) (field $value f64))))
  (type $_TopType (sub final $_Type (struct (field $field0 i32) (field $field1 i32))))
  (func $"dart2wasm._274 (import)"(import "dart2wasm" "_274") (param externref) (result externref))
  (func $"dart2wasm._275 (import)"(import "dart2wasm" "_275") (param externref) (result externref))
  (func $"dart2wasm._147 (import)"(import "dart2wasm" "_147") (param externref) (result f64))
  (func $"dart2wasm._148 (import)"(import "dart2wasm" "_148") (param f64) (result externref))
  (global $"C311 _TopType" (ref $_TopType) (i32.const 6) (i32.const 1) (struct.new $_TopType))
  (global $"numValueNullable initialized" (mut i32) (i32.const 0))
  (global $numValueNullable (mut (ref null $#Top)) (ref.null none))
  (global $"ktrue initialized" (mut i32) (i32.const 0))
  (global $ktrue (mut i32) (i32.const 0))
  (global $numValue (mut (ref null $#Top)) (ref.null none))
  (func $_TypeUniverse.isObjectInterfaceSubtype1 (param $var0 (ref $#Top)) (param $var1 i32) (param $var2 (ref $_Type)) (result i32))
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
      i32.const 76
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
    (local $var0 (ref null $#Top))
    (local $var1 (ref $#Top))
    (local $var2 externref)
    (local $var3 i32)
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
          local.tee $var3
          i32.const 63
          i32.eq
          br_if $label2
          drop
          i32.const 1
          local.get $var3
          i32.const 76
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
        i32.const 90
        i32.sub
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
            struct.get $#Top $field0
            i32.const 89
            i32.eq
            if
              unreachable
            else
              local.get $var1
              extern.externalize
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
    call $"sinkNumNullable <noInline>"
  )
  (func $isDartNull (param $var0 externref) (result i32))
  (func $sinkNumNullable <noInline> (param $var0 (ref null $BoxedDouble)))
  (func $jsifyNum (param $var0 (ref $#Top)) (result externref))
  (func $jsifyInt (param $var0 i64) (result externref))
  (func $_throwArgumentNullError <noInline> )
  (func $ktrue implicit getter (result i32))
  (func $numValue implicit getter (result (ref $#Top)))
  (func $sinkNum <noInline> (param $var0 f64))
)