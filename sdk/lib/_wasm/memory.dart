// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'dart:_wasm';

/// A [memory type] in WebAssembly, describing the address range and [Limits]
/// for memory instances.
///
/// Dart currently only supports 32-bit memory instances.
///
/// [memory type]: https://webassembly.github.io/spec/core/syntax/types.html#memory-types
@pragma("wasm:entry-point")
final class MemoryType {
  /// Minimum and optional maximum size for the memory.
  final Limits limits;

  const MemoryType({required this.limits});
}

/// Limits for the size of memories or tables in WebAssembly.
final class Limits {
  /// The minimum size for the memory instance (in units of WebAssembly pages).
  final int minimum;

  /// An optional maximum size for the instance (in units of WebAsembly pages).
  final int? maximum;

  const Limits(this.minimum, [this.maximum]);
}

/// An instance of linear memory available to this WebAssembly module.
///
/// ## Using memories
///
/// By default, compiling Dart to WebAssembly does not create a memory instance
/// (since Dart uses garbage collected types for everything instead). Especially
/// when interacting with other modules written in languages based on linear
/// memory though, it is necessary to access a linear memory instance from Dart.
///
/// [MemoryAccessExtension] provides methods to load and store values at certain
/// positions in a linear memory instance (e.g. [MemoryAccessExtension.loadInt8]
/// or [MemoryAccessExtension.storeInt8]), to inspect its
/// [MemoryAccessExtension.size] of memory or to [MemoryAccessExtension.grow]
/// it (if supported by the memory instance).
///
/// In WebAssembly, instructions can't be polymorphic with regards to the memory
/// instance they operate on: Each `i8.load` instruction has the target memory
/// instance encoded into it.
/// This also restricts how memory instances can be used in Dart: Every call
/// must use a top-level getter defining the memory as a receiver. It is not
/// allowed to call methods on other instances of [Memory]:
///
/// ```
/// @pragma('wasm:memory-type', MemoryType(limits: Limits(1, 10)))
/// external Memory get additionalMemory;
///
/// void main() {
///   // Allowed: Direct access to memory instance
///   print(additionalMemory.size);
///
///   // Not allowed: Loading a reference to the memory instance.
///   useMemory(additionalMemory);
/// }
///
/// void useMemory(Memory memory) {
///   // Not allowed: Dynamic memory instance.
///   memory.loadInt32(0, 1337);
/// }
/// ```
///
/// Further, tearing-off methods from [MemoryAccessExtension] is a compile-time
/// error.
///
/// ## Obtaining memory instances
///
/// To access linear memory, a [Memory] instance needs to be defined or
/// imported.
///
/// To define a memory instance, use a top-level getter defined as `external`
/// and with a [MemoryType] annotation:
///
/// ```
/// @pragma('wasm:memory-type', MemoryType(limits: Limits(1, 10)))
/// external Memory get additionalMemory;
/// ```
///
/// Memory instances can also be imported from the host environment by
/// annotating such getter with the `wasm:import` pragma:
///
/// ```
/// @pragma('wasm:memory-type', MemoryType(limits: Limits(1, 10)))
/// @pragma('wasm:import', 'module.name')
/// external Memory get mySecondMemory;
/// ```
///
/// ## Restrictions
///
/// Note that only 32-bit [Memory] instances are supported by Dart at the
/// moment.
@pragma("wasm:entry-point")
final class Memory {
  Memory._();

  /// The size of a page in WebAssembly memory.
  static const pageSize = 65536;
}

/// Operators accessing [Memory] instances in WebAssembly.
extension MemoryAccessExtension on Memory {
  /// Returns the size of this memory instance in units of [Memory.pageSize]
  /// (65536 bytes).
  @pragma("wasm:intrinsic")
  external int get size;

  /// Grows the size of this memory instance by the amount of [pages].
  ///
  /// This returns the old size (also in units of [Memory.pageSize]) if growing
  /// this memory instance was successful, or `-1` otherwise (e.g. due to an
  /// out-of-memory error).
  @pragma("wasm:intrinsic")
  external int grow(int pages);

  /// Copies the byte [value] to the memory region from [startOffset] to
  /// [startOffset] plus [length] (exclusive).
  ///
  /// This causes a WebAssembly trap if the target region is out-of-bounds for
  /// this memory.
  @pragma("wasm:intrinsic")
  external void fill(WasmI32 value, int startOffset, int length);

  @pragma("wasm:intrinsic")
  external WasmF32 loadFloat32(int address, {int align = 0, int offset = 0});
  @pragma("wasm:intrinsic")
  external WasmF64 loadFloat64(int address, {int align = 0, int offset = 0});

  @pragma("wasm:intrinsic")
  external WasmI32 loadInt8(int address, {int align = 0, int offset = 0});
  @pragma("wasm:intrinsic")
  external WasmI32 loadInt16(int address, {int align = 0, int offset = 0});
  @pragma("wasm:intrinsic")
  external WasmI32 loadInt32(int address, {int align = 0, int offset = 0});
  @pragma("wasm:intrinsic")
  external WasmI64 loadInt64(int address, {int align = 0, int offset = 0});

  @pragma("wasm:intrinsic")
  external WasmI32 loadUint8(int address, {int align = 0, int offset = 0});
  @pragma("wasm:intrinsic")
  external WasmI32 loadUint16(int address, {int align = 0, int offset = 0});
  @pragma("wasm:intrinsic")
  external WasmI32 loadUint32(int address, {int align = 0, int offset = 0});

  @pragma("wasm:intrinsic")
  external void storeFloat32(
    int address,
    WasmF32 value, {
    int align = 0,
    int offset = 0,
  });
  @pragma("wasm:intrinsic")
  external void storeFloat64(
    int address,
    WasmF64 value, {
    int align = 0,
    int offset = 0,
  });

  @pragma("wasm:intrinsic")
  external void storeInt8(
    int address,
    WasmI32 value, {
    int align = 0,
    int offset = 0,
  });
  @pragma("wasm:intrinsic")
  external void storeInt16(
    int address,
    WasmI32 value, {
    int align = 0,
    int offset = 0,
  });
  @pragma("wasm:intrinsic")
  external void storeInt32(
    int address,
    WasmI32 value, {
    int align = 0,
    int offset = 0,
  });
  @pragma("wasm:intrinsic")
  external void storeInt64(
    int address,
    WasmI64 value, {
    int align = 0,
    int offset = 0,
  });
}
