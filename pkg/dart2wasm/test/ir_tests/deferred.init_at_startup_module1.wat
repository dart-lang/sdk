(module $module1
  (type $#Top <...>)
  (type $Array<String?> <...>)
  (type $JSExternWrapper <...>)
  (global $"\"hello\"" (import "module0" "global0") (ref $JSExternWrapper))
  (table $module0.cross-module-funcs-0 (import "module0" "cross-module-funcs-0") 3 funcref)
  (global $array (mut (ref $Array<String?>))
    (array.new_fixed $Array<String?> 0))
  (elem $module0.cross-module-funcs-0
    (set 0 (ref.func $write))
    (set 1 (ref.func $read)))
  (func $#init
    i32.const 1
    array.new_default $Array<String?>
    global.set $array
  )
  (func $read (result (ref $JSExternWrapper))
    block $label0 (result (ref $JSExternWrapper))
      global.get $array
      i32.const 0
      array.get $Array<String?>
      br_on_non_null $label0
      i32.const 2
      call_indirect (result (ref none))
      unreachable
    end $label0
  )
  (func $write (result (ref null $#Top))
    (local $var0 (ref $JSExternWrapper))
    global.get $array
    i32.const 0
    global.get $"\"hello\""
    local.tee $var0
    array.set $Array<String?>
    local.get $var0
  )
)