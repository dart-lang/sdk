(module $module0
  (type $#Closure-0-1 <...>)
  (type $#Top <...>)
  (type $H0 (sub final $Object (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $fun (ref $#Closure-0-1)))))
  (type $Object <...>)
  (table $cross-module-funcs-0 (export "cross-module-funcs-0") 4 funcref)
  (func $"modMainUseH0 <noInline>"
    i64.const 0
    call $checkLibraryIsLoadedFromLoadId
    block $label0 (result (ref $H0))
      i32.const 2
      call_indirect $cross-module-funcs-0 (result (ref null $H0))
      br_on_non_null $label0
      i32.const 3
      call_indirect $cross-module-funcs-0 (result (ref $H0))
    end $label0
    call $print
    drop
    i64.const 0
    call $checkLibraryIsLoadedFromLoadId
    block $label1 (result (ref $H0))
      i32.const 2
      call_indirect $cross-module-funcs-0 (result (ref null $H0))
      br_on_non_null $label1
      i32.const 3
      call_indirect $cross-module-funcs-0 (result (ref $H0))
    end $label1
    drop
    i64.const 1
    i32.const 1
    call_indirect $cross-module-funcs-0 (param i64) (result (ref null $#Top))
    drop
  )
  (func $checkLibraryIsLoadedFromLoadId (param $var0 i64) <...>)
  (func $print (param $var0 (ref null $#Top)) (result (ref null $#Top)) <...>)
)