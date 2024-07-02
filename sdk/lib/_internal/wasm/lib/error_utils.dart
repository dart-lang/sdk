// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_wasm';

class IndexErrorUtils {
  /// Same as [IndexError.check], but assumes that [length] is positive and
  /// uses a single unsigned comparison. Always inlined.
  @pragma("wasm:prefer-inline")
  static void checkAssumePositiveLength(int index, int length) {
    if (WasmI64.fromInt(length).leU(WasmI64.fromInt(index))) {
      throw IndexError.withLength(index, length);
    }
  }
}

class RangeErrorUtils {
  /// Same as `RangeError.checkValueInInterval(value, 0, maxValue)`, but
  /// assumes that [maxValue] is positive and uses a single unsigned
  /// comparison. Always inlined.
  @pragma("wasm:prefer-inline")
  static void checkValueBetweenZeroAndPositiveMax(int value, int maxValue) {
    if (WasmI64.fromInt(maxValue).ltU(WasmI64.fromInt(value))) {
      throw RangeError.range(value, 0, maxValue);
    }
  }

  /// Same as [RangeError.checkValidRange], but assumes that [length] is
  /// positive and does less checks. Error reporting is also slightly
  /// different: when both [start] and [end] are negative, this reports [end]
  /// instead of [start]. Always inlined.
  @pragma("wasm:prefer-inline")
  static void checkValidRangePositiveLength(int start, int end, int length) {
    if (WasmI64.fromInt(length).ltU(WasmI64.fromInt(end))) {
      throw RangeError.range(end, 0, length);
    }
    if (WasmI64.fromInt(end).ltU(WasmI64.fromInt(start))) {
      throw RangeError.range(start, 0, end);
    }
  }
}
