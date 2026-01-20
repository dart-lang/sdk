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
  (type $type0 (func 
    (result (ref $MyConstClass))))
  (global $.h1-nonshared-const (import "" "h1-nonshared-const") (ref extern))
  (table $module0.static1-0 (import "module0" "static1-0") 1 (ref null $type0))
  (global $"C504 MyConstClass" (ref $MyConstClass)
    (i32.const 121)
    (i32.const 0)
    (i32.const 4)
    (i32.const 0)
    (global.get $.h1-nonshared-const)
    (struct.new $JSStringImpl)
    (struct.new $MyConstClass))
  (func $"modH1Use <noInline>" (param $var0 i32) (result (ref $MyConstClass))
    local.get $var0
    if (result (ref $MyConstClass))
      global.get $"C504 MyConstClass"
    else
      i32.const 0
      call_indirect $module0.static1-0 (result (ref $MyConstClass))
    end
  )
)