(module $module1
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
  (table $module0.cross-module-funcs-0 (import "module0" "cross-module-funcs-0") 17 funcref)
  (global $"\"bad\"" (ref $JSExternWrapper) <...>)
  (global $MyConstClass (ref $MyConstClass)
    (i32.const 111)
    (i32.const 0)
    (i32.const 108)
    (i32.const 0)
    (global.get $.h1-nonshared-const)
    (struct.new $JSExternWrapper)
    (struct.new $MyConstClass))
  (elem $module0.cross-module-funcs-0
    (set 0 (ref.func $int.parse))
    (set 1 (ref.func $"mainImpl <noInline>")))
  (func $"mainImpl <noInline>" (param $var0 i32) (result (ref null $#Top))
    (local $var1 (ref $MyConstClass))
    i64.const 0
    i32.const 2
    call_indirect $module0.cross-module-funcs-0 (param i64) (result i32)
    drop
    local.get $var0
    i32.const 3
    call_indirect $module0.cross-module-funcs-0 (param i32) (result (ref $MyConstClass))
    i64.const 1
    i32.const 2
    call_indirect $module0.cross-module-funcs-0 (param i64) (result i32)
    drop
    local.get $var0
    call $"modH1Use <noInline>"
    ref.eq
    i32.eqz
    if
      global.get $"\"bad\""
      i32.const 4
      call_indirect $module0.cross-module-funcs-0 (param (ref $#Top)) (result (ref none))
      unreachable
    end
    ref.null none
  )
  (func $"modH1Use <noInline>" (param $var0 i32) (result (ref $MyConstClass))
    local.get $var0
    if (result (ref $MyConstClass))
      global.get $MyConstClass
    else
      i32.const 16
      call_indirect $module0.cross-module-funcs-0 (result (ref $MyConstClass))
    end
  )
  (func $int.parse (result i64) <...>)
)