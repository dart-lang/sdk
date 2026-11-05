(module $M
  (type $#Top <...>)
  (type $Array<WasmI16> <...>)
  (type $Array<WasmI32> <...>)
  (type $JSExternWrapper <...>)
  (type $JavaScriptStack <...>)
  (tag $WebAssembly.JSTag (import "WebAssembly" "JSTag") (param externref))
  (tag $tag0 (param (ref $#Top) (ref $#Top)))
  (global $"WasmArray<WasmI16>[717]" (ref $Array<WasmI16>) <...>)
  (global $"WasmArray<WasmI32>[250]" (ref $Array<WasmI32>) <...>)
  (global $"WasmArray<WasmI32>[717]" (ref $Array<WasmI32>) <...>)
  (global $"\"Caught Error\"" (ref $JSExternWrapper) <...>)
  (global $"\"Caught JSAny\"" (ref $JSExternWrapper) <...>)
  (global $"\"Caught Object\"" (ref $JSExternWrapper) <...>)
  (global $"\"Finally\"" (ref $JSExternWrapper) <...>)
  (func $boxJsException (param $var0 externref) (result (ref $#Top)) <...>)
  (func $f  <...>)
  (func $jsExceptionStackTrace (param $var0 externref) (result (ref $JavaScriptStack)) <...>)
  (func $print (param $var0 (ref $#Top)) <...>)
  (@binaryen.inline 0)
  (func $tryBlocks1
    (local $var0 i32)
    (local $var1 (ref null $#Top))
    (local $var2 (ref null $#Top))
    (local $var3 exnref)
    (local $var4 externref)
    block $label0
      block $label1
        block $label2 (result externref) (result (ref exn))
          block $label3 (result (ref $#Top)) (result (ref $#Top)) (result (ref exn))
            try_table $label4 (catch_ref $tag0 $label3) (catch_ref $WebAssembly.JSTag $label2)
              call $f
              br $label0
            end
            unreachable
          end $label3
          local.set $var3
          local.set $var2
          local.tee $var1
          struct.get $#Top $#classId
          local.tee $var0
          i32.const 67
          i32.eq
          if (result i32)
            i32.const 0
          else
            block $label5 (result i32)
              i32.const -1
              global.get $"WasmArray<WasmI32>[250]"
              i32.const 67
              array.get $Array<WasmI32>
              local.get $var0
              i32.add
              local.tee $var0
              i32.const 717
              i32.ge_u
              br_if $label5
              drop
              global.get $"WasmArray<WasmI32>[717]"
              local.get $var0
              array.get $Array<WasmI32>
              i32.const 67
              i32.eq
              if
                global.get $"WasmArray<WasmI16>[717]"
                local.get $var0
                array.get_u $Array<WasmI16>
                br $label5
              end
              i32.const -1
            end $label5
          end
          i32.const -1
          i32.ne
          br_if $label1
          local.get $var3
          ref.as_non_null
          throw_ref
        end $label2
        drop
        local.tee $var4
        call $boxJsException
        local.get $var4
        call $jsExceptionStackTrace
        drop
        drop
      end $label1
      global.get $"\"Caught JSAny\""
      call $print
    end $label0
  )
  (@binaryen.inline 0)
  (func $tryBlocks2
    (local $var0 (ref $#Top))
    (local $var1 (ref $#Top))
    (local $var2 (ref exn))
    (local $var3 externref)
    block $label0
      block $label1 (result (ref $#Top)) (result (ref $#Top))
        block $label2 (result externref) (result (ref exn))
          block $label3 (result (ref $#Top)) (result (ref $#Top)) (result (ref exn))
            try_table $label4 (catch_ref $tag0 $label3) (catch_ref $WebAssembly.JSTag $label2)
              call $f
              br $label0
            end
            unreachable
          end $label3
          local.set $var2
          local.set $var1
          local.tee $var0
          local.get $var1
          br $label1
        end $label2
        drop
        local.tee $var3
        call $boxJsException
        local.get $var3
        call $jsExceptionStackTrace
      end $label1
      drop
      drop
      global.get $"\"Caught Object\""
      call $print
    end $label0
  )
  (@binaryen.inline 0)
  (func $tryBlocks3
    (local $var0 i32)
    (local $var1 (ref null $#Top))
    (local $var2 (ref null $#Top))
    (local $var3 exnref)
    block $label0
      block $label1 (result i32)
        block $label2
          block $label3 (result (ref $#Top)) (result (ref $#Top)) (result (ref exn))
            try_table $label4 (catch_ref $tag0 $label3)
              call $f
              br $label0
            end
            unreachable
          end $label3
          local.set $var3
          local.set $var2
          local.tee $var1
          struct.get $#Top $#classId
          local.tee $var0
          i32.const 55
          i32.le_u
          if
            local.get $var0
            i32.const 41
            i32.le_u
            if
              i32.const 1
              local.get $var0
              i32.const 41
              i32.eq
              br_if $label1
              drop
              br $label2
            end
            i32.const 1
            local.get $var0
            i32.const 44
            i32.ge_u
            br_if $label1
            drop
            br $label2
          end
          local.get $var0
          i32.const 105
          i32.le_u
          if
            i32.const 1
            local.get $var0
            i32.const 105
            i32.eq
            br_if $label1
            drop
            br $label2
          end
          i32.const 1
          local.get $var0
          i32.const 107
          i32.eq
          br_if $label1
          drop
        end $label2
        i32.const 0
      end $label1
      i32.eqz
      if
        local.get $var3
        ref.as_non_null
        throw_ref
      end
      global.get $"\"Caught Error\""
      call $print
    end $label0
  )
  (@binaryen.inline 0)
  (func $tryBlocksFinally (param $var0 i64) (result i64)
    (local $var1 (ref exn))
    block $label0
      block $label1
        block $label2
          block $label3 (result (ref exn))
            try_table $label4 (catch_all_ref $label3)
              local.get $var0
              i64.const 1
              i64.eq
              br_if $label1
              call $f
            end
            br $label2
          end $label3
          global.get $"\"Finally\""
          call $print
          throw_ref
        end $label2
        global.get $"\"Finally\""
        call $print
        br $label0
      end $label1
      global.get $"\"Finally\""
      call $print
      i64.const 10
      return
    end $label0
    i64.const 20
  )
)