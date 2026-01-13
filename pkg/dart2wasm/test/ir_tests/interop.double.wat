(module $module0
  (type $#Top (struct
    (field $field0 i32)))
  (type $BoxedDouble (sub final $#Top (struct
    (field $field0 i32)
    (field $value f64))))
  (func $"dart2wasm._168 (import)" (import "dart2wasm" "_168") (param externref) (result f64))
  (func $"dart2wasm._295 (import)" (import "dart2wasm" "_295") (param f64) (result externref))
  (func $"dart2wasm._296 (import)" (import "dart2wasm" "_296") (param externref) (result externref))
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
    (local $var0 (ref null $BoxedDouble))
    (local $var1 externref)
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
    local.tee $var0
    ref.is_null
    if (result externref)
      ref.null noextern
    else
      local.get $var0
      call $jsifyRaw
    end
    call $"dart2wasm._296 (import)"
    local.tee $var1
    call $isDartNull
    if (result (ref null $BoxedDouble))
      ref.null none
    else
      i32.const 87
      local.get $var1
      call $"dart2wasm._168 (import)"
      struct.new $BoxedDouble
    end
    call $"sinkDoubleNullable <noInline>"
  )
  (func $isDartNull (param $var0 externref) (result i32) <...>)
  (func $jsifyRaw (param $var0 (ref null $#Top)) (result externref) <...>)
)