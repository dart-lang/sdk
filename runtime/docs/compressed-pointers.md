# Compressed Pointers

Some Dart applications run in memory-constrained environments such as smart phones and assistant devices. They don’t need a full 64-bit address space, easily fitting into the 4GB available to a 32-bit address space, so memory can be saved by reducing the size of object pointers from 64 to 32 bits.

If the heap is restricted to some 4GB-aligned region of the 64-bit address space, pointers can be compressed to 32-bits by dropping the upper bits during a store, and decompressed back to 64-bits after a load by adding the heap base address. (If our heap was at the low 4GB, adding the heap base would be unnecessary, but this portion of the address space is already occupied by [ART](https://source.android.com/docs/core/runtime).)

If the heap was nothing but pointers, this would reduce memory usage by half. In practice the heap is a mixture of pointers and bytes that won’t be compressed. Also some objects won’t be smaller because all sizes are rounded up to the allocation unit. In practice heap usage is reduced by 20-30% rather than 50%. Also a program's memory usage involves more than the Dart heap, the rest of which is not reduced by Dart pointer compression.

Because we decompress by unconditionally adding the heap base, if the pointer was in fact a [Smi](glossary.md), the upper 32 bits are now garbage instead of sign extended. To account for this, uses of Smis must use 32-bit operations instead of 64-bit operations for things like comparison or using a Smi value as an array index. [V8](https://v8.dev/blog/pointer-compression) follows the same strategy and called it "Smi-corrupting".

| Operation     | Uncompressed     | Compressed                           |
| ------------- | ---------------- | ------------------------------------ |
| Load pointer  | `ldr x0, [x1, #9]` | `ldr w0, [x1, #9]`<br>`add x0, x0, x28` |
| Load pointer, known Smi  | `ldr x0, [x1, #9]` | `ldrs w0, [x1, #9]`  |
| Store pointer | `str x0, [x1, #9]` | `str w0, [x1, #9]` |
| Smi add       | `add x0, x1, x2` | `add w0, w1, w2` |
| Smi compare   | `cmp x0, x1` | `cmp w0, w1` |
| Smi indexing  | `ldr x0, [x1, x2 lsl 2]` | `ldr x0, [x1, w2 sxtw 2]` |

We do not compress every pointer in the Dart heap. In particular, ObjectPool is uncompressed. Every entry in the pool exists because it will be used by at least one load in the compiled code. Saving 32 bits per entry costs an additional 32-bit instruction on the load side, and some entries are used by more than one load, so using compressed pointers for the pool would be a net size increase.

Some applications do need more than 4GB of memory, so we support both compressed and full pointer modes as a build-time option. We generally use full pointers for desktop/server and compressed pointers for mobile.

Because all isolate groups share some read-only objects such as null and common stub code, all isolate groups occupy the same 4GB region. If we were to move these objects into the isolate groups' own heaps, each isolate group could have an independent 4GB allocation limit.

Because we do not control the address of snapshots loaded by dlopen, such that they might be outside the 4GB region, we do not place read-only data objects like strings into the snapshot image to be directly referenced and loaded lazily by demand paging. Instead they are deserialized into the compressed heap and so brought into memory eagerly.
