// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch, unsafeCast;
import 'dart:_js_types';
import 'dart:_js_helper';

@patch
bool tryCopyExternalIntTypedData(
  Iterable<int> from,
  _IntListMixin to,
  int start,
  int skipCount,
  int count,
) {
  if (from is JSIntegerArrayBase) {
    // We only add this mixin to typed lists in this library so we know
    // `this` is `TypedData`.
    final fromTypedData = unsafeCast<JSIntegerArrayBase>(from);

    final fromElementSize = fromTypedData.elementSizeInBytes;
    if (fromElementSize == 1 && to is WasmI8ArrayBase) {
      final destTypedData = unsafeCast<WasmI8ArrayBase>(to);
      copyToWasmI8Array(
        fromTypedData.toJSArrayExternRef()!,
        skipCount,
        destTypedData.data,
        destTypedData.offsetInElements + start,
        count,
      );
      return true;
    }
    if (fromElementSize == 2 && to is WasmI16ArrayBase) {
      final destTypedData = unsafeCast<WasmI16ArrayBase>(to);
      copyToWasmI16Array(
        fromTypedData.toJSArrayExternRef()!,
        skipCount,
        destTypedData.data,
        destTypedData.offsetInElements + start,
        count,
      );
      return true;
    }
    if (fromElementSize == 4 && to is _WasmI32ArrayBase) {
      final destTypedData = unsafeCast<_WasmI32ArrayBase>(to);
      copyToWasmI32Array(
        fromTypedData.toJSArrayExternRef()!,
        skipCount,
        destTypedData.data,
        destTypedData.offsetInElements + start,
        count,
      );
      return true;
    }

    // NOTICE: We currently don't have `JSUint64Array` classes in
    // `dart:js_interop`.
  }

  return false;
}

@patch
bool tryCopyExternalFloatTypedData(
  Iterable<double> from,
  _DoubleListMixin to,
  int start,
  int skipCount,
  int count,
) {
  if (from is JSFloatArrayBase) {
    // We only add this mixin to typed lists in this library so we know
    // `this` is `TypedData`.
    final fromTypedData = unsafeCast<JSFloatArrayBase>(from);

    final fromElementSize = fromTypedData.elementSizeInBytes;
    if (fromElementSize == 4 && to is _WasmF32ArrayBase) {
      final destTypedData = unsafeCast<_WasmF32ArrayBase>(to);
      copyToWasmF32Array(
        fromTypedData.toJSArrayExternRef()!,
        skipCount,
        destTypedData.data,
        destTypedData.offsetInElements + start,
        count,
      );
      return true;
    }
    if (fromElementSize == 8 && to is _WasmF64ArrayBase) {
      final destTypedData = unsafeCast<_WasmF64ArrayBase>(to);
      copyToWasmF64Array(
        fromTypedData.toJSArrayExternRef()!,
        skipCount,
        destTypedData.data,
        destTypedData.offsetInElements + start,
        count,
      );
      return true;
    }
  }

  return false;
}
