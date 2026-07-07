(module $M
  (type $#Top <...>)
  (type $ArgumentError <...>)
  (type $Array<Object?> <...>)
  (type $Array<String> <...>)
  (type $Array<WasmArray<WasmI8>?> <...>)
  (type $Array<WasmI8> <...>)
  (type $Array<int> <...>)
  (type $JSExternWrapper <...>)
  (type $Object <...>)
  (func $"wasm:js-string.charCodeAt (import)" (import "wasm:js-string" "charCodeAt") (param externref i32) (result i32))
  (@binaryen.removable.if.unused)
  (func $"wasm:js-string.concat (import)" (import "wasm:js-string" "concat") (param externref externref) (result (ref extern)))
  (@binaryen.removable.if.unused)
  (func $"wasm:js-string.equals (import)" (import "wasm:js-string" "equals") (param externref externref) (result i32))
  (@binaryen.removable.if.unused)
  (func $"wasm:js-string.length (import)" (import "wasm:js-string" "length") (param externref) (result i32))
  (table $cross-module-funcs-0 (export "cross-module-funcs-0") 17 funcref)
  (global $"\"1.0\"" (ref $JSExternWrapper) <...>)
  (global $BoxedDouble._cacheKeys (mut (ref $Array<int>)) <...>)
  (global $BoxedDouble._cacheValues (mut (ref $Array<String>)) <...>)
  (global $_deletedDataMarker (mut (ref $#Top)) <...>)
  (global $deferredLoadLists (ref $Array<WasmArray<WasmI8>?>) <...>)
  (elem $cross-module-funcs-0
    (set 3 (ref.func $"wasm:js-string.length (import)"))
    (set 4 (ref.func $JSStringImpl._interpolate))
    (set 5 (ref.func $_throwIndexError))
    (set 6 (ref.func $"wasm:js-string.charCodeAt (import)"))
    (set 7 (ref.func $JSStringImpl.substring))
    (set 8 (ref.func $"wasm:js-string.concat (import)"))
    (set 9 (ref.func $JSStringImpl.fromRefUnchecked))
    (set 10 (ref.func $ArgumentError))
    (set 11 (ref.func $Error._throwWithCurrentStackTrace))
    (set 12 (ref.func $BoxedInt.toRadixString))
    (set 13 (ref.func $"wasm:js-string.equals (import)"))
    (set 14 (ref.func $JSStringImpl._interpolate4))
    (set 15 (ref.func $IntegerDivisionByZeroException))
    (set 16 (ref.func $_TypeError._throwNullCheckErrorWithCurrentStack)))
  (func $#init
    global.get $"\"1.0\""
    i32.const 16
    array.new $Array<String>
    global.set $BoxedDouble._cacheValues
    i64.const 4607182418800017408
    i32.const 16
    array.new $Array<int>
    global.set $BoxedDouble._cacheKeys
    i32.const 1
    i32.const 0
    struct.new $Object
    global.set $_deletedDataMarker
    global.get $deferredLoadLists
    i32.const 1
    i32.const 0
    i32.const 2
    array.new_data $Array<WasmI8>$data0
    array.set $Array<WasmArray<WasmI8>?>
  )
  (func $ArgumentError (param $var0 (ref null $#Top)) (param $var1 (ref null $JSExternWrapper)) (result (ref $ArgumentError)) <...>)
  (func $BoxedInt.toRadixString (param $var0 i64) (param $var1 i64) (result (ref $JSExternWrapper)) <...>)
  (func $Error._throwWithCurrentStackTrace (param $var0 (ref $#Top)) <...>)
  (func $IntegerDivisionByZeroException (result (ref $Object)) <...>)
  (func $JSStringImpl._interpolate (param $var0 (ref $Array<Object?>)) (result (ref $JSExternWrapper)) <...>)
  (func $JSStringImpl._interpolate4 (param $var0 (ref null $#Top)) (param $var1 (ref null $#Top)) (param $var2 (ref null $#Top)) (param $var3 (ref null $#Top)) (result (ref $JSExternWrapper)) <...>)
  (func $JSStringImpl.fromRefUnchecked (param $var0 externref) (result (ref $JSExternWrapper)) <...>)
  (func $JSStringImpl.substring (param $var0 (ref $JSExternWrapper)) (param $var1 i64) (param $var2 i64) (result (ref $JSExternWrapper)) <...>)
  (func $_TypeError._throwNullCheckErrorWithCurrentStack  <...>)
  (func $_throwIndexError (param $var0 i64) (param $var1 i64) (param $var2 (ref null $JSExternWrapper)) <...>)
  (data $data0 <... 2 bytes ...>)
)