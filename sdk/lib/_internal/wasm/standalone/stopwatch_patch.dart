// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch;
import 'dart:_embedder';

@patch
class Stopwatch {
  @patch
  static int _initTicker() {
    final frequency = monotonicClockFrequency().toIntUnsigned();
    if (frequency != 1000 && frequency != 1000000) {
      throw AssertionError(
        'dart:monotonicClockFrequency import must return either 1kHz or 1MHz.',
      );
    }
    return frequency;
  }

  @patch
  static int _now() => monotonicClockTicks().toInt();

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
