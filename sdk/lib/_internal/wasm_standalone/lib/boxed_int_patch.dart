// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_embedder' show i64ToString;
import 'dart:_error_utils';
import 'dart:_internal';
import 'dart:_string';
import 'dart:_wasm';

@patch
class BoxedInt {
  @patch
  String toRadixString(int radix) {
    RangeErrorUtils.checkValueInInterval(radix, 2, 36, "radix");
    return _intToString(this, radix);
  }

  @patch
  String toString() => _intToString(this, 10);
}

String _intToString(int value, int radix) {
  return JSStringImpl.fromRefUnchecked(
    i64ToString(WasmI64.fromInt(value), WasmI32.fromInt(radix)),
  );
}
