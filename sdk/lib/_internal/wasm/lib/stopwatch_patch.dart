// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

@pragma("wasm:import", "dart2wasm.performanceNow")
external double _performanceNow();

@patch
class Stopwatch {
  @patch
  static int _initTicker() {
    return 1000;
  }

  @patch
  static int _now() => _performanceNow().toInt();

  @patch
  int get elapsedMicroseconds => 1000 * elapsedTicks;

  @patch
  int get elapsedMilliseconds => elapsedTicks;
}
