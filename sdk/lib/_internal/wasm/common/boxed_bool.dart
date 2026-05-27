// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_wasm';

@pragma("wasm:entry-point")
final class BoxedBool extends bool {
  @pragma("wasm:entry-point")
  final WasmI32 value;

  @pragma("wasm:entry-point")
  external BoxedBool();

  @override
  bool operator ==(Object other) {
    return other is bool
        ? this ==
              other // Intrinsic ==
        : false;
  }

  bool operator &(bool other) => this & other; // Intrinsic &
  bool operator ^(bool other) => this ^ other; // Intrinsic ^
  bool operator |(bool other) => this | other; // Intrinsic |
}
