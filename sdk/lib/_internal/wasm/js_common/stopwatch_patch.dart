// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch;
import 'dart:_js_helper' show JS;
import 'dart:_wasm';

@patch
class Stopwatch {
  static int Function() _timerTicks = () {
    return JS<WasmF64>("() => Date.now()").toDouble().toInt();
  };

  @patch
  static int _initTicker() {
    if (JS<WasmI32>("() => typeof dartUseDateNowForTicks !== \"undefined\"")
        .toBool()) {
      // Millisecond precision, as int.
      return 1000;
    } else {
      // Microsecond precision as double. Convert to int without losing
      // precision.
      _timerTicks = () {
        return JS<WasmF64>("() => 1000 * performance.now()").toDouble().toInt();
      };
      return 1000000;
    }
  }

  @patch
  static int _now() => _timerTicks();

  @patch
  int get elapsedMicroseconds {
    int ticks = elapsedTicks;
    if (_frequency == 1000000) return ticks;
    assert(_frequency == 1000);
    return ticks * 1000;
  }

  @patch
  int get elapsedMilliseconds {
    int ticks = elapsedTicks;
    if (_frequency == 1000) return ticks;
    assert(_frequency == 1000000);
    return ticks ~/ 1000;
  }
}
