(module $M1
  (type $#Top <...>)
  (type $Array<WasmI16> <...>)
  (type $JSExternWrapper <...>)
  (type $Array<String?> <...>)
  (table $M.cross-module-funcs-0 (import "M" "cross-module-funcs-0") 17 funcref)
  (global $"\"hello\"" (ref $JSExternWrapper) <...>)
  (global $JSStringImpl._stringFromCodePointBuffer (mut (ref $Array<WasmI16>)) <...>)
  (global $array (mut (ref $Array<String?>))
    (array.new_fixed $Array<String?> 0))
  (elem $M.cross-module-funcs-0
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
  (func $Expect.equals (param $var0 (ref null $#Top)) <...>)
  (func $read (result (ref $JSExternWrapper))
    block $label0 (result (ref $JSExternWrapper))
      global.get $array
      i32.const 0
      array.get $Array<String?>
      br_on_non_null $label0
      i32.const 16
      call_indirect $M.cross-module-funcs-0 
      unreachable
    end $label0
  )
  (func $write (result (ref $JSExternWrapper))
    global.get $array
    i32.const 0
    global.get $"\"hello\""
    array.set $Array<String?>
    global.get $"\"hello\""
  )
)