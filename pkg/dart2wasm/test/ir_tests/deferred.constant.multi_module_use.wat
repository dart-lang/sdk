(module $module0
  (type $#Top (struct
    (field $field0 i32)))
  (type $JSStringImpl (sub final $Object (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $_ref externref))))
  (type $MyConstClass (sub final $Object (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $b (ref $JSStringImpl)))))
  (type $Object (sub $#Top (struct
    (field $field0 i32)
    (field $field1 (mut i32)))))
  (type $type0 (func 
    (param $var0 i32)
    (result (ref $MyConstClass))))
  (type $type2 (func 
    (result (ref $MyConstClass))))
  (table $static0-0 (export "static0-0") 2 (ref null $type0))
  (table $static1-0 (export "static1-0") 1 (ref null $type2))
  (global $"C383 \"bad\"" (ref $JSStringImpl) <...>)
  (func $"mainImpl <noInline>" (param $var0 i32)
    (local $var1 (ref $MyConstClass))
    i64.const 0
    call $checkLibraryIsLoadedFromLoadId
    local.get $var0
    i32.const 0
    call_indirect $static0-0 (param i32) (result (ref $MyConstClass))
    i64.const 1
    call $checkLibraryIsLoadedFromLoadId
    local.get $var0
    i32.const 1
    call_indirect $static0-0 (param i32) (result (ref $MyConstClass))
    ref.eq
    i32.eqz
    if
      global.get $"C383 \"bad\""
      call $Error._throwWithCurrentStackTrace
      unreachable
    end
  )
  (func $Error._throwWithCurrentStackTrace (param $var0 (ref $#Top)) <...>)
  (func $checkLibraryIsLoadedFromLoadId (param $var0 i64) <...>)
)