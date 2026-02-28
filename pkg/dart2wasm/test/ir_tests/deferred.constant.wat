(module $module0
  (type $#Closure-0-1 <...>)
  (type $#Top <...>)
  (type $Array<Object?> <...>)
  (type $Array<_Type> <...>)
  (type $H0 (sub final $Object (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $fun (ref $#Closure-0-1)))))
  (type $JSExternWrapper <...>)
  (type $Object <...>)
  (type $_FunctionType <...>)
  (table $cross-module-funcs-0 (export "cross-module-funcs-0") 9 funcref)
  (elem $cross-module-funcs-0
    (set 1 (ref.func $"_hashSeed implicit getter"))
    (set 2 (ref.func $SystemHash.combine))
    (set 3 (ref.func $_TypeUniverse.substituteFunctionTypeArgument))
    (set 4 (ref.func $print))
    (set 5 (ref.func $JSStringImpl._interpolate)))
  (func $_hashSeed implicit getter (result i64) <...>)
  (func $"modMainUseH0 <noInline>"
    i64.const 0
    call $checkLibraryIsLoadedFromLoadId
    block $label0 (result (ref $H0))
      i32.const 7
      call_indirect $cross-module-funcs-0 (result (ref null $H0))
      br_on_non_null $label0
      i32.const 8
      call_indirect $cross-module-funcs-0 (result (ref $H0))
    end $label0
    call $print
    drop
    i64.const 0
    call $checkLibraryIsLoadedFromLoadId
    block $label1 (result (ref $H0))
      i32.const 7
      call_indirect $cross-module-funcs-0 (result (ref null $H0))
      br_on_non_null $label1
      i32.const 8
      call_indirect $cross-module-funcs-0 (result (ref $H0))
    end $label1
    drop
    i64.const 1
    i32.const 6
    call_indirect $cross-module-funcs-0 (param i64) (result (ref null $#Top))
    drop
  )
  (func $JSStringImpl._interpolate (param $var0 (ref $Array<Object?>)) (result (ref $JSExternWrapper)) <...>)
  (func $SystemHash.combine (param $var0 i64) (param $var1 i64) (result i64) <...>)
  (func $_TypeUniverse.substituteFunctionTypeArgument (param $var0 (ref $_FunctionType)) (param $var1 (ref $Array<_Type>)) (result (ref $_FunctionType)) <...>)
  (func $checkLibraryIsLoadedFromLoadId (param $var0 i64) <...>)
  (func $print (param $var0 (ref null $#Top)) (result (ref null $#Top)) <...>)
)