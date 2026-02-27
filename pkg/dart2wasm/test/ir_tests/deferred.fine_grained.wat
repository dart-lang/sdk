(module $module0
  (type $#Top <...>)
  (type $Array<Object?> <...>)
  (type $BoxedInt <...>)
  (type $JSStringImpl <...>)
  (type $JavaScriptStack <...>)
  (type $Object <...>)
  (type $WasmListBase <...>)
  (type $_Future <...>)
  (type $_Type <...>)
  (rec
    (type $type0 <...>)
    (type $_AsyncSuspendState <...>)
  )
  (global $".FooConst0(" (import "" "FooConst0(") (ref extern))
  (global $".FooConstBase(" (import "" "FooConstBase(") (ref extern))
  (table $cross-module-funcs-0 (export "cross-module-funcs-0") 34 funcref)
  (global $"\")\"" (ref $JSStringImpl) <...>)
  (global $"\"FooConst0(\"" (ref $JSStringImpl)
    (i32.const 4)
    (i32.const 0)
    (global.get $".FooConst0(")
    (struct.new $JSStringImpl))
  (global $"\"FooConstBase(\"" (ref $JSStringImpl)
    (i32.const 4)
    (i32.const 0)
    (global.get $".FooConstBase(")
    (struct.new $JSStringImpl))
  (global $"\"foo0Code(\"" (ref $JSStringImpl) <...>)
  (global $0 (ref $BoxedInt) <...>)
  (global $FooConst0 (ref $Object)
    (i32.const 122)
    (i32.const 0)
    (struct.new $Object))
  (global $fooGlobal0 (mut (ref null $#Top))
    (ref.null none))
  (elem $cross-module-funcs-0
    (set 1 (ref.func $_makeFuture))
    (set 2 (ref.func $_newAsyncSuspendState))
    (set 3 (ref.func $loadLibraryFromLoadId))
    (set 4 (ref.func $_awaitHelper))
    (set 5 (ref.func $checkLibraryIsLoadedFromLoadId))
    (set 7 (ref.func $_AsyncSuspendState._complete))
    (set 8 (ref.func $_AsyncSuspendState._completeError))
    (set 9 (ref.func $boxJsException))
    (set 10 (ref.func $jsExceptionStackTrace))
    (set 14 (ref.func $print))
    (set 15 (ref.func $JSStringImpl._interpolate3))
    (set 16 (ref.func $"fooGlobal0 implicit getter"))
    (set 17 (ref.func $"foo0Code <noInline>"))
    (set 26 (ref.func $"_throwIndexError <noInline>"))
    (set 27 (ref.func $FooConstBase.doit))
    (set 28 (ref.func $GrowableList._withData))
    (set 29 (ref.func $int.parse)))
  (func $_throwIndexError <noInline> (param $var0 i64) (param $var1 i64) (param $var2 (ref null $JSStringImpl)) (result (ref none)) <...>)
  (func $"foo0Code <noInline>" (param $var0 (ref null $#Top)) (result (ref null $#Top))
    global.get $FooConst0
    call $print
    drop
    global.get $"\"foo0Code(\""
    local.get $var0
    global.get $"\")\""
    call $JSStringImpl._interpolate3
    call $print
    drop
    global.get $0
    global.set $fooGlobal0
    ref.null none
  )
  (func $fooGlobal0 implicit getter (result (ref $#Top)) <...>)
  (func $FooConst0.doit (param $var0 (ref $Object)) (param $var1 (ref null $#Top)) (result (ref null $#Top))
    global.get $"\"FooConst0(\""
    local.get $var1
    global.get $"\")\""
    call $JSStringImpl._interpolate3
    call $print
    drop
    local.get $var0
    local.get $var1
    call $FooConstBase.doit
    drop
    ref.null none
  )
  (func $FooConstBase.doit (param $var0 (ref $Object)) (param $var1 (ref null $#Top)) (result (ref null $#Top))
    global.get $"\"FooConstBase(\""
    local.get $var1
    global.get $"\")\""
    call $JSStringImpl._interpolate3
    call $print
    drop
    ref.null none
  )
  (func $GrowableList._withData (param $var0 (ref $_Type)) (param $var1 (ref $Array<Object?>)) (result (ref $WasmListBase)) <...>)
  (func $JSStringImpl._interpolate3 (param $var0 (ref null $#Top)) (param $var1 (ref null $#Top)) (param $var2 (ref null $#Top)) (result (ref $JSStringImpl)) <...>)
  (func $_AsyncSuspendState._complete (param $var0 (ref $_AsyncSuspendState)) (param $var1 (ref null $#Top)) (result (ref null $#Top)) <...>)
  (func $_AsyncSuspendState._completeError (param $var0 (ref $_AsyncSuspendState)) (param $var1 (ref $#Top)) (param $var2 (ref $Object)) (result (ref null $#Top)) <...>)
  (func $_awaitHelper (param $var0 (ref $_AsyncSuspendState)) (param $var1 (ref $_Future)) (result (ref null $#Top)) <...>)
  (func $_makeFuture (param $var0 (ref $_Type)) (result (ref $_Future)) <...>)
  (func $_newAsyncSuspendState (param $var0 (ref $type0)) (param $var1 structref) (param $var2 (ref $_Future)) (result (ref $_AsyncSuspendState)) <...>)
  (func $boxJsException (param $var0 externref) (result (ref $#Top)) <...>)
  (func $checkLibraryIsLoadedFromLoadId (param $var0 i64) (result i32) <...>)
  (func $int.parse (param $var0 (ref $JSStringImpl)) (result i64) <...>)
  (func $jsExceptionStackTrace (param $var0 externref) (result (ref $JavaScriptStack)) <...>)
  (func $loadLibraryFromLoadId (param $var0 i64) (result (ref $_Future)) <...>)
  (func $print (param $var0 (ref null $#Top)) (result (ref null $#Top)) <...>)
)