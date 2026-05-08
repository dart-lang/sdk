(module $module1
  (type $#Top <...>)
  (type $Array<String?> <...>)
  (type $Array<WasmI16> <...>)
  (type $JSExternWrapper <...>)
  (table $module0.cross-module-funcs-0 (import "module0" "cross-module-funcs-0") 20 funcref)
  (global $"\"hello\"" (ref $JSExternWrapper) <...>)
  (global $JSStringImpl._stringFromCodePointBuffer (mut (ref $Array<WasmI16>)) <...>)
  (global $array (mut (ref $Array<String?>))
    (array.new_fixed $Array<String?> 0))
  (elem $module0.cross-module-funcs-0
    (set 0 (ref.func $write))
    (set 1 (ref.func $read))
    (set 2 (ref.func $Expect.equals)))
  (func $#init
    i32.const 2
    array.new_default $Array<WasmI16>
    global.set $JSStringImpl._stringFromCodePointBuffer
    i32.const 1
    array.new_default $Array<String?>
    global.set $array
  )
  (func $Expect.equals (param $var0 (ref null $#Top)) (result (ref null $#Top)) <...>)
  (func $read (result (ref $JSExternWrapper))
    block $label0 (result (ref $JSExternWrapper))
      global.get $array
      i32.const 0
      array.get $Array<String?>
      br_on_non_null $label0
      i32.const 19
      call_indirect $module0.cross-module-funcs-0 (result (ref none))
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