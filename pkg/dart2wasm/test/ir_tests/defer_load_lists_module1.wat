(module $M1
  (type $Array<WasmArray<WasmI8>?> <...>)
  (type $Array<WasmI8> <...>)
  (global $deferredLoadLists (import "M" "global3") (ref $Array<WasmArray<WasmI8>?>))
  (func $#init
    global.get $deferredLoadLists
    i32.const 2
    i32.const 0
    i32.const 2
    array.new_data $Array<WasmI8>$data0
    array.set $Array<WasmArray<WasmI8>?>
    global.get $deferredLoadLists
    i32.const 3
    i32.const 2
    i32.const 2
    array.new_data $Array<WasmI8>$data0
    array.set $Array<WasmArray<WasmI8>?>
  )
  (data $data0 <... 4 bytes ...>)
)