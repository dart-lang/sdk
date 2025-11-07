(module $module3
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
  (global $S.shared-const (import "S" "shared-const") (ref extern))
  (global $S.h0-nonshared-const (import "S" "h0-nonshared-const") (ref extern))
  (table $module0.constant-table0 (import "module0" "constant-table0") 1 (ref null $JSStringImpl))
  (table $module0.constant-table1 (import "module0" "constant-table1") 1 (ref null $MyConstClass))
  (global $"C492 MyConstClass" (ref $MyConstClass)
    (i32.const 107)
    (i32.const 0)
    (i32.const 4)
    (i32.const 0)
    (global.get $S.h0-nonshared-const)
    (struct.new $JSStringImpl)
    (struct.new $MyConstClass))
  (func $"modH0Use <noInline>" (param $var0 i32) (result (ref $MyConstClass))
    (local $var1 (ref $JSStringImpl))
    (local $var2 (ref $MyConstClass))
    local.get $var0
    if (result (ref $MyConstClass))
      global.get $"C492 MyConstClass"
    else
      block $label0 (result (ref $MyConstClass))
        i32.const 0
        table.get $module0.constant-table1
        br_on_non_null $label0
        i32.const 0
        i32.const 107
        i32.const 0
        block $label1 (result (ref $JSStringImpl))
          i32.const 0
          table.get $module0.constant-table0
          br_on_non_null $label1
          i32.const 0
          i32.const 4
          i32.const 0
          global.get $S.shared-const
          struct.new $JSStringImpl
          local.tee $var1
          table.set $module0.constant-table0
          local.get $var1
        end $label1
        struct.new $MyConstClass
        local.tee $var2
        table.set $module0.constant-table1
        local.get $var2
      end $label0
    end
  )
)