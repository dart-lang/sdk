(module $M
  (type $Base <...>)
  (type $Holder (struct
    (field $field (ref $Base))))
  (@binaryen.inline 0)
  (func $readX (param $var0 (ref $Holder)) (result i64)
    (local $var1 (ref $Base))
    local.get $var0
    struct.get $Holder $field
    local.tee $var1
    struct.get $Base $x
    local.get $var1
    struct.get $Base $y
    i64.add
  )
)