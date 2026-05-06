// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_embedder';
import "dart:_internal" show patch;
import 'dart:_string';
import 'dart:_wasm';

@patch
class DateTime {
  @patch
  static int _getCurrentMicros() => currentTimeMicros().toInt();

  @patch
  static String _timeZoneNameForClampedSeconds(int secondsSinceEpoch) =>
      JSStringImpl.fromRefUnchecked(
        timeZoneNameForClampedSeconds(WasmI64.fromInt(secondsSinceEpoch)),
      );

  // In Dart, the offset is the difference between local time and UTC,
  // while in JS, the offset is the difference between UTC and local time.
  // As a result, the signs are opposite, so we negate the value returned by JS.
  @patch
  static int _timeZoneOffsetInSecondsForClampedSeconds(int secondsSinceEpoch) =>
      timeZoneOffsetInSecondsForClampedSeconds(
        WasmI64.fromInt(secondsSinceEpoch),
      ).toIntSigned();
}
