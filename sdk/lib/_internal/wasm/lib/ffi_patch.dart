// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal";
import "dart:_wasm";

@patch
final class Pointer<T extends NativeType> {
  @pragma("wasm:entry-point")
  WasmI32 _address;

  Pointer._(this._address);

  @patch
  int get address => _address.toIntUnsigned();

  @pragma("wasm:entry-point")
  @pragma("wasm:prefer-inline")
  factory Pointer._fromAddressI32(WasmI32 address) => Pointer._(address);
}

@patch
@pragma("wasm:prefer-inline")
Pointer<T> _fromAddress<T extends NativeType>(int address) =>
    Pointer._(WasmI32.fromInt(address));

@patch
@pragma("wasm:prefer-inline")
Pointer<S> _loadPointer<S extends NativeType>(
  Object typedDataBase,
  int offsetInBytes,
) => Pointer<S>.fromAddress(_loadUint32(typedDataBase, offsetInBytes));

@patch
@pragma("wasm:prefer-inline")
void _storePointer<S extends NativeType>(
  Object typedDataBase,
  int offsetInBytes,
  Pointer<S> value,
) => _storeUint32(typedDataBase, offsetInBytes, value._address.toIntUnsigned());
