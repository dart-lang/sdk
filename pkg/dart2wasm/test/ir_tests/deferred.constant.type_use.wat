(module $module0
  (type $#Top <...>)
  (type $JSExternWrapper <...>)
  (table $cross-module-funcs-0 (export "cross-module-funcs-0") 4 funcref)
  (elem $cross-module-funcs-0
    (set 1 (ref.func $checkLibraryIsLoadedFromLoadId))
    (set 2 (ref.func $JSStringImpl._interpolate2))
    (set 3 (ref.func $print)))
  (func $JSStringImpl._interpolate2 (param $var0 (ref null $#Top)) (param $var1 (ref null $#Top)) (result (ref $JSExternWrapper)) <...>)
  (func $checkLibraryIsLoadedFromLoadId (param $var0 i64) (result i32) <...>)
  (func $print (param $var0 (ref null $#Top)) <...>)
)