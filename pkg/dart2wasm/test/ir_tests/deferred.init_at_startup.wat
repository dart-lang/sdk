(module $module0
  (type $#Top <...>)
  (type $Array<String> <...>)
  (type $Array<WasmI16> <...>)
  (type $Array<int> <...>)
  (type $JSExternWrapper <...>)
  (type $Object <...>)
  (table $cross-module-funcs-0 (export "cross-module-funcs-0") 3 funcref)
  (global $"\"1.0\"" (ref $JSExternWrapper) <...>)
  (global $BoxedDouble._cacheKeys (mut (ref $Array<int>)) <...>)
  (global $BoxedDouble._cacheValues (mut (ref $Array<String>)) <...>)
  (global $JSStringImpl._stringFromCodePointBuffer (mut (ref $Array<WasmI16>)) <...>)
  (global $_deletedDataMarker (mut (ref $#Top)) <...>)
  (elem $cross-module-funcs-0
    (set 2 (ref.func $"_TypeError._throwNullCheckErrorWithCurrentStack <noInline>")))
  (func $_TypeError._throwNullCheckErrorWithCurrentStack <noInline> (result (ref none)) <...>)
  (func $#init
    global.get $"\"1.0\""
    i32.const 16
    array.new $Array<String>
    global.set $BoxedDouble._cacheValues
    i64.const 4607182418800017408
    i32.const 16
    array.new $Array<int>
    global.set $BoxedDouble._cacheKeys
    i32.const 2
    array.new_default $Array<WasmI16>
    global.set $JSStringImpl._stringFromCodePointBuffer
    i32.const 1
    i32.const 0
    struct.new $Object
    global.set $_deletedDataMarker
  )
)