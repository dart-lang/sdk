(module $module0
  (type $#Top <...>)
  (type $ArgumentError <...>)
  (type $Array<Object?> <...>)
  (type $Array<String> <...>)
  (type $Array<int> <...>)
  (type $JSExternWrapper <...>)
  (type $Object <...>)
  (func $"dart2wasm.H (import)" (import "dart2wasm" "H") (param i32 i32) (result externref))
  (func $"dart2wasm.I (import)" (import "dart2wasm" "I") (param i64 i32) (result externref))
  (func $"wasm:js-string.charCodeAt (import)" (import "wasm:js-string" "charCodeAt") (param externref i32) (result i32))
  (@binaryen.removable.if.unused)
  (func $"wasm:js-string.equals (import)" (import "wasm:js-string" "equals") (param externref externref) (result i32))
  (@binaryen.removable.if.unused)
  (func $"wasm:js-string.length (import)" (import "wasm:js-string" "length") (param externref) (result i32))
  (table $cross-module-funcs-0 (export "cross-module-funcs-0") 20 funcref)
  (global $"\"1.0\"" (ref $JSExternWrapper) <...>)
  (global $BoxedDouble._cacheKeys (mut (ref $Array<int>)) <...>)
  (global $BoxedDouble._cacheValues (mut (ref $Array<String>)) <...>)
  (global $_deletedDataMarker (mut (ref $#Top)) <...>)
  (elem $cross-module-funcs-0
    (set 3 (ref.func $"wasm:js-string.length (import)"))
    (set 4 (ref.func $JSStringImpl._interpolate))
    (set 5 (ref.func $JSStringImpl.toString))
    (set 6 (ref.func $"_throwIndexError <noInline>"))
    (set 7 (ref.func $"wasm:js-string.charCodeAt (import)"))
    (set 8 (ref.func $JSStringImpl.substring))
    (set 9 (ref.func $JSStringImpl.+))
    (set 10 (ref.func $ArgumentError))
    (set 11 (ref.func $"Error._throwWithCurrentStackTrace <noInline>"))
    (set 12 (ref.func $JSStringImpl.fromRefUnchecked))
    (set 13 (ref.func $"_throwRangeError <noInline>"))
    (set 14 (ref.func $"dart2wasm.H (import)"))
    (set 15 (ref.func $"dart2wasm.I (import)"))
    (set 16 (ref.func $"wasm:js-string.equals (import)"))
    (set 17 (ref.func $JSStringImpl._interpolate4))
    (set 18 (ref.func $IntegerDivisionByZeroException))
    (set 19 (ref.func $"_TypeError._throwNullCheckErrorWithCurrentStack <noInline>")))
  (func $Error._throwWithCurrentStackTrace <noInline> (param $var0 (ref $#Top)) (result (ref none)) <...>)
  (func $_TypeError._throwNullCheckErrorWithCurrentStack <noInline> (result (ref none)) <...>)
  (func $_throwIndexError <noInline> (param $var0 i64) (param $var1 i64) (param $var2 (ref null $JSExternWrapper)) (result (ref none)) <...>)
  (func $_throwRangeError <noInline> (param $var0 i64) (param $var1 i64) (param $var2 i64) (param $var3 (ref null $JSExternWrapper)) (param $var4 (ref null $JSExternWrapper)) (result (ref none)) <...>)
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
  )
  (func $ArgumentError (param $var0 (ref null $#Top)) (param $var1 (ref null $JSExternWrapper)) (result (ref $ArgumentError)) <...>)
  (func $IntegerDivisionByZeroException (result (ref $Object)) <...>)
  (func $JSStringImpl.+ (param $var0 (ref $JSExternWrapper)) (param $var1 (ref $JSExternWrapper)) (result (ref $JSExternWrapper)) <...>)
  (func $JSStringImpl._interpolate (param $var0 (ref $Array<Object?>)) (result (ref $JSExternWrapper)) <...>)
  (func $JSStringImpl._interpolate4 (param $var0 (ref null $#Top)) (param $var1 (ref null $#Top)) (param $var2 (ref null $#Top)) (param $var3 (ref null $#Top)) (result (ref $JSExternWrapper)) <...>)
  (func $JSStringImpl.fromRefUnchecked (param $var0 externref) (result (ref $JSExternWrapper)) <...>)
  (func $JSStringImpl.substring (param $var0 (ref $JSExternWrapper)) (param $var1 i64) (param $var2 i64) (result (ref $JSExternWrapper)) <...>)
  (func $JSStringImpl.toString (param $var0 (ref $#Top)) (result (ref $JSExternWrapper)) <...>)
)