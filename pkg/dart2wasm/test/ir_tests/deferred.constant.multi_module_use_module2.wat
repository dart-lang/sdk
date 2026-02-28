(module $module2
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
  (global $.shared-const (import "" "shared-const") (ref extern))
  (global $MyConstClass (ref $MyConstClass)
    (i32.const 122)
    (i32.const 0)
    (i32.const 104)
    (i32.const 0)
    (global.get $.shared-const)
    (struct.new $JSExternWrapper)
    (struct.new $MyConstClass))
)