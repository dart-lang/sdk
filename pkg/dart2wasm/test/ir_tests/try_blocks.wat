(module $module0
  (type $#Top <...>)
  (type $Array<WasmI16> <...>)
  (type $Array<WasmI32> <...>)
  (type $JSExternWrapper <...>)
  (type $JavaScriptStack <...>)
  (tag $tag0 (param (ref $#Top) (ref $#Top)))
  (global $"WasmArray<WasmI16>[748]" (ref $Array<WasmI16>) <...>)
  (global $"WasmArray<WasmI32>[225]" (ref $Array<WasmI32>) <...>)
  (global $"WasmArray<WasmI32>[748]" (ref $Array<WasmI32>) <...>)
  (global $"\"Caught Error\"" (ref $JSExternWrapper) <...>)
  (global $"\"Caught JSAny\"" (ref $JSExternWrapper) <...>)
  (global $"\"Caught Object\"" (ref $JSExternWrapper) <...>)
  (func $f <noInline>  <...>)
  (func $"tryBlocks1 <noInline>"
    (local $var0 i32)
    (local $var1 (ref $#Top))
    (local $var2 (ref $#Top))
    (local $var3 (ref $#Top))
    (local $var4 externref)
    block $label0
      block $label1 (result (ref $#Top)) (result (ref $#Top))
        try $label2
          call $"f <noInline>"
          br $label0
        catch $tag0
          local.set $var3
          local.set $var2
          local.get $var2
          local.tee $var1
          local.get $var3
          local.get $var1
          struct.get $#Top $field0
          local.tee $var0
          i32.const 76
          i32.eq
          if (result i32)
            i32.const 0
          else
            block $label3 (result i32)
              i32.const -1
              global.get $"WasmArray<WasmI32>[225]"
              i32.const 76
              array.get $Array<WasmI32>
              local.get $var0
              i32.add
              local.tee $var0
              i32.const 748
              i32.ge_u
              br_if $label3
              drop
              global.get $"WasmArray<WasmI32>[748]"
              local.get $var0
              array.get $Array<WasmI32>
              i32.const 76
              i32.eq
              if
                global.get $"WasmArray<WasmI16>[748]"
                local.get $var0
                array.get_u $Array<WasmI16>
                br $label3
              end
              i32.const -1
            end $label3
          end
          i32.const -1
          i32.ne
          br_if $label1
          drop
          drop
          rethrow $label2
        catch $WebAssembly.JSTag
          local.tee $var4
          call $boxJsException
          local.get $var4
          call $jsExceptionStackTrace
          br $label1
        end $label2
        unreachable
      end $label1
      drop
      drop
      global.get $"\"Caught JSAny\""
      call $print
    end $label0
  )
  (func $"tryBlocks2 <noInline>"
    (local $var0 (ref $#Top))
    (local $var1 (ref $#Top))
    (local $var2 (ref $#Top))
    (local $var3 externref)
    block $label0
      block $label1 (result (ref $#Top)) (result (ref $#Top))
        try $label2
          call $"f <noInline>"
          br $label0
        catch $tag0
          local.set $var1
          local.set $var0
          local.get $var0
          local.get $var1
          br $label1
        catch $WebAssembly.JSTag
          local.tee $var3
          call $boxJsException
          local.get $var3
          call $jsExceptionStackTrace
          br $label1
        end
        unreachable
      end $label1
      drop
      drop
      global.get $"\"Caught Object\""
      call $print
    end $label0
  )
  (func $"tryBlocks3 <noInline>"
    (local $var0 i32)
    (local $var1 (ref $#Top))
    (local $var2 (ref $#Top))
    block $label0
      block $label1
        try $label2
          call $"f <noInline>"
          br $label0
        catch $tag0
          local.set $var2
          local.set $var1
          block $label3 (result i32)
            i32.const 1
            local.get $var1
            struct.get $#Top $field0
            local.tee $var0
            i32.const 40
            i32.eq
            br_if $label3
            drop
            i32.const 1
            local.get $var0
            i32.const 43
            i32.sub
            i32.const 12
            i32.lt_u
            br_if $label3
            drop
            i32.const 1
            local.get $var0
            i32.const 99
            i32.sub
            i32.const 2
            i32.lt_u
            br_if $label3
            drop
            i32.const 0
          end $label3
          br_if $label1
          rethrow $label2
        end $label2
        unreachable
      end $label1
      global.get $"\"Caught Error\""
      call $print
    end $label0
  )
  (func $boxJsException (param $var0 externref) (result (ref $#Top)) <...>)
  (func $jsExceptionStackTrace (param $var0 externref) (result (ref $JavaScriptStack)) <...>)
  (func $print (param $var0 (ref $#Top)) <...>)
)