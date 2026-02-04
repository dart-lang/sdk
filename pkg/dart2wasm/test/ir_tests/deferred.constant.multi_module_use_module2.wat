(module $module2
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
  (global $.shared-const (import "" "shared-const") (ref extern))
  (global $"C501 MyConstClass" (ref $MyConstClass)
    (i32.const 118)
    (i32.const 0)
    (i32.const 4)
    (i32.const 0)
    (global.get $.shared-const)
    (struct.new $JSStringImpl)
    (struct.new $MyConstClass))
)