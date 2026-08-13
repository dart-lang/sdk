(module $M1
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
  (global $.h1-nonshared-const (import "" "h1-nonshared-const") (ref extern))
  (global $.shared-const (import "" "shared-const") (ref extern))
  (table $M.cross-module-funcs-0 (import "M" "cross-module-funcs-0") 17 funcref)
  (global $"\"bad\"" (ref $JSExternWrapper) <...>)
  (global $MyConstClass (ref $MyConstClass)
    (i32.const 110)
    (i32.const 0)
    (i32.const 67)
    (i32.const 0)
    (global.get $.h1-nonshared-const)
    (struct.new $JSExternWrapper)
    (struct.new $MyConstClass))
  (global $MyConstClass_15 (ref $MyConstClass)
    (i32.const 110)
    (i32.const 0)
    (i32.const 67)
    (i32.const 0)
    (global.get $.shared-const)
    (struct.new $JSExternWrapper)
    (struct.new $MyConstClass))
  (elem $M.cross-module-funcs-0
    (set 0 (ref.func $int.parse))
    (set 1 (ref.func $mainImpl))
    (set 16 (ref.func $0)))
  (func $null (result (ref $MyConstClass)) <...>)
  (func $int.parse (result i64) <...>)
  (@binaryen.inline 0)
  (func $mainImpl (param $var0 i32)
    i64.const 1
    i32.const 2
    call_indirect $M.cross-module-funcs-0 (param i64) (result i32)
    drop
    local.get $var0
    i32.const 3
    call_indirect $M.cross-module-funcs-0 (param i32) (result (ref $MyConstClass))
    i64.const 2
    i32.const 2
    call_indirect $M.cross-module-funcs-0 (param i64) (result i32)
    drop
    local.get $var0
    call $modH1Use
    ref.eq
    i32.eqz
    if
      global.get $"\"bad\""
      i32.const 4
      call_indirect $M.cross-module-funcs-0 (param (ref $#Top))
      unreachable
    end
  )
  (@binaryen.inline 0)
  (func $modH1Use (param $var0 i32) (result (ref $MyConstClass))
    global.get $MyConstClass
    global.get $MyConstClass_15
    local.get $var0
    select (ref $MyConstClass)
  )
)