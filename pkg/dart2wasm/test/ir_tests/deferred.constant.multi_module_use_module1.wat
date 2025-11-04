(module $module1
  (type $#Top (struct
    (field $field0 i32)))
  (type $Object (sub $#Top (struct
    (field $field0 i32)
    (field $field1 (mut i32)))))
  (type $JSStringImpl (sub final $Object (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $_ref externref))))
  (type $MyConstClass (sub final $Object (struct
    (field $field0 i32)
    (field $field1 (mut i32))
    (field $b (ref $JSStringImpl)))))
  (global $S.h1-nonshared-const (import "S" "h1-nonshared-const") (ref extern))
  (global $S.shared-const (import "S" "shared-const") (ref extern))
  (global $"C489 \"shared-const\"" (import "module0" "global0") (ref null $JSStringImpl))
  (global $"C490 MyConstClass" (import "module0" "global1") (ref null $MyConstClass))
  (global $"C488 MyConstClass" (ref $MyConstClass)
    (i32.const 107)
    (i32.const 0)
    (i32.const 4)
    (i32.const 0)
    (global.get $S.h1-nonshared-const)
    (struct.new $JSStringImpl)
    (struct.new $MyConstClass))
  (func $"modH1Use <noInline>" (param $var0 i32) (result (ref $MyConstClass))
    (local $var1 (ref $JSStringImpl))
    (local $var2 (ref $MyConstClass))
    local.get $var0
    if (result (ref $MyConstClass))
      global.get $"C488 MyConstClass"
    else
      block $label0 (result (ref $MyConstClass))
        global.get $"C490 MyConstClass"
        br_on_non_null $label0
        i32.const 107
        i32.const 0
        block $label1 (result (ref $JSStringImpl))
          global.get $"C489 \"shared-const\""
          br_on_non_null $label1
          i32.const 4
          i32.const 0
          global.get $S.shared-const
          struct.new $JSStringImpl
          local.tee $var1
          global.set $"C489 \"shared-const\""
          local.get $var1
        end $label1
        struct.new $MyConstClass
        local.tee $var2
        global.set $"C490 MyConstClass"
        local.get $var2
      end $label0
    end
  )
)