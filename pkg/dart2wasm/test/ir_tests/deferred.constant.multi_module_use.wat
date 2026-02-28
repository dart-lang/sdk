(module $module0
  (type $#Top (struct
    (field $field0 i32)))
  (type $JSExternWrapper (sub $Object (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $_externRef externref))))
  (type $MyConstClass (sub final $Object (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $b (ref $JSExternWrapper)))))
  (type $Object (sub $#Top (struct
    (field $field0 i32)
    (field $field1 (mut i32)))))
  (table $cross-module-funcs-0 (export "cross-module-funcs-0") 3 funcref)
  (global $"\"bad\"" (ref $JSExternWrapper) <...>)
  (func $Error._throwWithCurrentStackTrace <noInline> (param $var0 (ref $#Top)) <...>)
  (func $"mainImpl <noInline>" (param $var0 i32)
    (local $var1 (ref $MyConstClass))
    i64.const 0
    call $checkLibraryIsLoadedFromLoadId
    local.get $var0
    i32.const 0
    call_indirect $cross-module-funcs-0 (param i32) (result (ref $MyConstClass))
    i64.const 1
    call $checkLibraryIsLoadedFromLoadId
    local.get $var0
    i32.const 1
    call_indirect $cross-module-funcs-0 (param i32) (result (ref $MyConstClass))
    ref.eq
    i32.eqz
    if
      global.get $"\"bad\""
      call $"Error._throwWithCurrentStackTrace <noInline>"
      unreachable
    end
  )
  (func $checkLibraryIsLoadedFromLoadId (param $var0 i64) <...>)
)