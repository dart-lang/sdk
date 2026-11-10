(module $M2
  (type $Array<WasmArray<WasmI8>?> <...>)
  (type $Array<WasmI8> <...>)
  (global $deferredLoadLists (import "M" "global3") (ref $Array<WasmArray<WasmI8>?>))
  (func $#init
    global.get $deferredLoadLists
    i32.const 5
    i32.const 1
    i32.const 5
    array.new_fixed $Array<WasmI8> 2
    array.set $Array<WasmArray<WasmI8>?>
    global.get $deferredLoadLists
    i32.const 6
    i32.const 1
    i32.const 6
    array.new_fixed $Array<WasmI8> 2
    array.set $Array<WasmArray<WasmI8>?>
  )
)