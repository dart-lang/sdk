(module $M
  (type $#Top <...>)
  (type $Array<String> <...>)
  (type $Array<WasmArray<WasmI8>?> <...>)
  (type $Array<WasmI8> <...>)
  (type $Array<int> <...>)
  (type $ImmutableArray<WasmExternRef> <...>)
  (type $JSExternWrapper <...>)
  (type $Object <...>)
  (global $"\"1.0\"" (ref $JSExternWrapper) <...>)
  (global $BoxedDouble._cacheKeys (mut (ref $Array<int>)) <...>)
  (global $BoxedDouble._cacheValues (mut (ref $Array<String>)) <...>)
  (global $_deletedDataMarker (mut (ref $#Top)) <...>)
  (global $deferredLoadLists (mut (ref $Array<WasmArray<WasmI8>?>)) <...>)
  (global $loadIdModuleImportInfo (mut (ref null $ImmutableArray<WasmExternRef>))
    (ref.null none))
  (func $#init
    global.get $"\"1.0\""
    i32.const 16
    array.new $Array<String>
    global.set $BoxedDouble._cacheValues
    i64.const 4607182418800017408
    i32.const 16
    array.new $Array<int>
    global.set $BoxedDouble._cacheKeys
    i32.const 1
    i32.const 0
    struct.new $Object
    global.set $_deletedDataMarker
    global.get $deferredLoadLists
    i32.const 1
    i32.const 0
    i32.const 2
    array.new_data $Array<WasmI8>$data0
    array.set $Array<WasmArray<WasmI8>?>
    global.get $deferredLoadLists
    i32.const 4
    i32.const 2
    i32.const 2
    array.new_data $Array<WasmI8>$data0
    array.set $Array<WasmArray<WasmI8>?>
  )
  (data $data0 <... 4 bytes ...>)
)