// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/flutter/flutter/issues/79441.

import 'dart:ffi';

// FFI signature
typedef _dart_memset = void Function(Pointer<Uint8>, int, int);
typedef _c_memset = Void Function(Pointer<Uint8>, Int32, IntPtr);

_dart_memset? fbMemset;

void _fallbackMemset(Pointer<Uint8> ptr, int byte, int size) {
  final bytes = ptr.cast<Uint8>();
  for (var i = 0; i < size; i++) {
    bytes[i] = byte;
  }
}

void main() {
  try {
    fbMemset = DynamicLibrary.process()
        .lookupFunction<_c_memset, _dart_memset>('memset');
  } catch (_) {
    // This works:
    // fbMemset = _fallbackMemset;

    // This doesn't: /aot/precompiler.cc: 2761: error: unreachable code
    fbMemset = (Pointer<Uint8> ptr, int byte, int size) {
      final bytes = ptr.cast<Uint8>();
      for (var i = 0; i < size; i++) {
        bytes[i] = byte;
      }
    };
  }
}
