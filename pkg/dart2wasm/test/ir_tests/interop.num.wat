(module $module0
  (type $#Top (struct
    (field $field0 i32)))
  (type $BoxedDouble (sub final $#Top (struct
    (field $field0 i32)
    (field $value f64))))
  (func $"dart2wasm._168 (import)" (import "dart2wasm" "_168") (param externref) (result f64))
  (func $"dart2wasm._169 (import)" (import "dart2wasm" "_169") (param f64) (result externref))
  (func $"dart2wasm._295 (import)" (import "dart2wasm" "_295") (param externref) (result externref))
  (func $"dart2wasm._296 (import)" (import "dart2wasm" "_296") (param externref) (result externref))
  (global $"numValueNullable initialized" (mut i32) <...>)
  (global $numValueNullable (mut (ref null $#Top)) <...>)
  (func $_throwArgumentNullError <noInline>  <...>)
  (func $ktrue implicit getter (result i32) <...>)
  (func $numValue implicit getter (result (ref $#Top)) <...>)
  (func $sinkNum <noInline> (param $var0 f64) <...>)
  (func $sinkNumNullable <noInline> (param $var0 (ref null $BoxedDouble)) <...>)
  (func $"testNumConstant <noInline>"
    (local $var0 externref)
    i64.const 1
    call $jsifyInt
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
    call $"sinkNum <noInline>"
  )
  (func $"testNumConstantDouble <noInline>"
    (local $var0 externref)
    f64.const 1.1
    call $"dart2wasm._169 (import)"
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
    call $"sinkNum <noInline>"
  )
  (func $"testNumConstantNullable <noInline>"
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
    call $"sinkNumNullable <noInline>"
  )
  (func $"testNumValue <noInline>"
    (local $var0 externref)
    call $"numValue implicit getter"
    call $jsifyNum
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
    call $"sinkNum <noInline>"
  )
  (func $"testNumValueNullable <noInline>"
    (local $var0 (ref null $#Top))
    (local $var1 externref)
    global.get $"numValueNullable initialized"
    i32.eqz
    if
      call $"ktrue implicit getter"
      if (result (ref null $#Top))
        call $"numValue implicit getter"
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
    call $"sinkNumNullable <noInline>"
  )
  (func $isDartNull (param $var0 externref) (result i32) <...>)
  (func $jsifyInt (param $var0 i64) (result externref) <...>)
  (func $jsifyNum (param $var0 (ref $#Top)) (result externref) <...>)
  (func $jsifyRaw (param $var0 (ref null $#Top)) (result externref) <...>)
)