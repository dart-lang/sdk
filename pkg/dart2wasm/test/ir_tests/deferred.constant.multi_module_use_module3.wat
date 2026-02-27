(module $module3
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
  (global $.h1-nonshared-const (import "" "h1-nonshared-const") (ref extern))
  (table $module0.cross-module-funcs-0 (import "module0" "cross-module-funcs-0") 3 funcref)
  (global $MyConstClass (ref $MyConstClass)
    (i32.const 122)
    (i32.const 0)
    (i32.const 4)
    (i32.const 0)
    (global.get $.h1-nonshared-const)
    (struct.new $JSStringImpl)
    (struct.new $MyConstClass))
  (elem $module0.cross-module-funcs-0
    (set 1 (ref.func $"modH1Use <noInline>")))
  (func $"modH1Use <noInline>" (param $var0 i32) (result (ref $MyConstClass))
    local.get $var0
    if (result (ref $MyConstClass))
      global.get $MyConstClass
    else
      i32.const 2
      call_indirect (result (ref $MyConstClass))
    end
  )
)