(module $module0
  (type $#Top <...>)
  (type $Object <...>)
  (type $#Closure-0-1 <...>)
  (type $H0 (sub final $Object (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $fun (ref $#Closure-0-1)))))
  (type $type234 <...>)
  (type $type237 <...>)
  (type $type240 <...>)
  (table $static1-0 (export "static1-0") 1 (ref null $type240))
  (table $static2-0 (export "static2-0") 1 (ref null $type234))
  (table $static3-0 (export "static3-0") 1 (ref null $type237))
  (func $print (param $var0 (ref null $#Top)) (result (ref null $#Top)) <...>)
  (func $"modMainUseH0 <noInline>"
    i64.const 0
    call $checkLibraryIsLoadedFromLoadId
    block $label0 (result (ref $H0))
      i32.const 0
      call_indirect $static2-0 (result (ref null $H0))
      br_on_non_null $label0
      i32.const 0
      call_indirect $static3-0 (result (ref $H0))
    end $label0
    call $print
    drop
    i64.const 0
    call $checkLibraryIsLoadedFromLoadId
    block $label1 (result (ref $H0))
      i32.const 0
      call_indirect $static2-0 (result (ref null $H0))
      br_on_non_null $label1
      i32.const 0
      call_indirect $static3-0 (result (ref $H0))
    end $label1
    drop
    i64.const 1
    i32.const 0
    call_indirect $static1-0 (param i64) (result (ref null $#Top))
    drop
  )
  (func $checkLibraryIsLoadedFromLoadId (param $var0 i64) <...>)
)