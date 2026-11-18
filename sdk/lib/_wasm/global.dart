// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'dart:_wasm';

@pragma("wasm:entry-point")
final class Global<T extends WasmBase> {
  const Global._();
}

@pragma("wasm:entry-point")
final class MutableGlobal<T extends WasmBase> {
  const MutableGlobal._();
}

extension GlobalGet<T extends WasmBase> on Global<T> {
  /// Loads the value of a global using the `global.get` wasm instruction.
  @pragma("wasm:intrinsic")
  external T get value;
}

extension GlobalSet<T extends WasmBase> on MutableGlobal<T> {
  /// Loads the value of a global using the `global.get` wasm instruction.
  @pragma("wasm:intrinsic")
  external T get value;

  /// Stores a value in the global variable using the `global.set` wasm
  /// instruction.
  @pragma("wasm:intrinsic")
  external set value(T value);
}
