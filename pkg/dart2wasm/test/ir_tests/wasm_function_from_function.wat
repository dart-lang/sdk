(module $M
  (type $#Closure-0-1 <...>)
  (type $#Top <...>)
  (type $#Vtable-0-1 <...>)
  (type $BoxedInt <...>)
  (type $JSExternWrapper <...>)
  (type $type0 <...>)
  (func $"outside.registerCallback (import)" (import "outside" "registerCallback") (param (ref func)))
  (global $"\" instead.\"" (ref $JSExternWrapper) <...>)
  (global $"\"Hello\"" (ref $JSExternWrapper) <...>)
  (global $"\"Too few arguments passed. Expe<...>\"" (ref $JSExternWrapper) <...>)
  (global $"jsCallback1 tear-off" (ref $#Closure-0-1) <...>)
  (global $"jsCallback2 tear-off" (ref $#Closure-0-1) <...>)
  (func $Error._throwWithCurrentStackTrace (param $var0 (ref $#Top)) <...>)
  (func $JSStringImpl._interpolate3 (param $var0 (ref $JSExternWrapper)) (param $var1 (ref $#Top)) (param $var2 (ref $JSExternWrapper)) (result (ref $JSExternWrapper)) <...>)
  (func $JSValue.box (param $var0 externref) (result (ref null $JSExternWrapper)) <...>)
  (@binaryen.js.called)
  (func $_JS_Trampoline_FunctionToJSExportedDartFunction|get#toJS_16 (param $var0 (ref extern)) (param $var1 i32) (param $var2 (ref extern)) (param $var3 externref) (result externref)
    (local $var4 (ref $#Closure-0-1))
    (local $var5 i64)
    local.get $var1
    i64.extend_i32_s
    local.tee $var5
    i64.const 0
    i64.gt_s
    if
      local.get $var2
      any.convert_extern
      ref.cast $#Closure-0-1
      local.tee $var4
      struct.get $#Closure-0-1 $context
      local.get $var3
      call $JSValue.box
      local.get $var4
      struct.get $#Closure-0-1 $vtable
      struct.get $#Vtable-0-1 $closureCallEntry-0-1
      call_ref $type0
      drop
    end
    local.get $var5
    i64.const 0
    i64.gt_s
    if
      local.get $var0
      any.convert_extern
      ref.cast $#Closure-0-1
      local.tee $var4
      struct.get $#Closure-0-1 $context
      local.get $var3
      call $JSValue.box
      local.get $var4
      struct.get $#Closure-0-1 $vtable
      struct.get $#Vtable-0-1 $closureCallEntry-0-1
      call_ref $type0
      drop
      ref.null noextern
      return
    end
    global.get $"\"Too few arguments passed. Expe<...>\""
    i32.const 58
    local.get $var5
    struct.new $BoxedInt
    global.get $"\" instead.\""
    call $JSStringImpl._interpolate3
    call $Error._throwWithCurrentStackTrace
    unreachable
  )
  (@binaryen.js.called)
  (func $dartFunction
    global.get $"\"Hello\""
    call $print
  )
  (func $makeJsCallback (param $var0 (ref $#Closure-0-1)) (result (ref $JSExternWrapper)) <...>)
  (func $print (param $var0 (ref $#Top)) <...>)
  (@binaryen.inline 0)
  (func $runTest
    ref.func $dartFunction
    call $"outside.registerCallback (import)"
    global.get $"jsCallback1 tear-off"
    call $makeJsCallback
    call $print
    global.get $"jsCallback2 tear-off"
    call $makeJsCallback
    call $print
  )
)