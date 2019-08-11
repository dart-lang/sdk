// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--deterministic --optimization-counter-threshold=102 --optimization-filter=Box_

import 'package:expect/expect.dart';

const int kLimit = 100;

main() {
  // Get all 3 functions optimized with _Smi's.
  optimizeMilliseconds(1);
  optimizeMicroseconds(1);
  optimizeConstructor(1);

  // Now we trigger a store of a _Mint into the Box._value
  testMints(2048);
}

@pragma('vm:never-inline')
optimizeConstructor(int value) {
  for (int i = 0; i < kLimit; ++i) {
    new Box(milliseconds: value);
  }
}

@pragma('vm:never-inline')
optimizeMicroseconds(int value) {
  final d = new Box(milliseconds: value);
  for (int i = 0; i < kLimit; ++i) {
    Expect.equals(value * 1000, d.inMicroseconds);
  }
}

@pragma('vm:never-inline')
optimizeMilliseconds(int value) {
  final d = new Box(seconds: value);
  for (int i = 0; i < kLimit; ++i) {
    Expect.equals(value * 1000, d.inMilliseconds);
  }
}

@pragma('vm:never-inline')
testMints(int value) {
  final d = new Box(seconds: value);
  for (int i = 0; i < kLimit; ++i) {
    Expect.equals(value * 1000 * 1000, d.inMicroseconds);
    Expect.equals(value * 1000, d.inMilliseconds);
  }
}

int c = 0;

class Box {
  final int _value;

  @pragma('vm:never-inline')
  Box(
      {int days: 0,
      int hours: 0,
      int minutes: 0,
      int seconds: 0,
      int milliseconds: 0,
      int microseconds: 0})
      : this._microseconds(1000 * 1000 * 60 * 60 * 24 * days +
            1000 * 1000 * 60 * 60 * hours +
            1000 * 1000 * 60 * minutes +
            1000 * 1000 * seconds +
            1000 * milliseconds +
            microseconds);

  Box._microseconds(this._value);

  @pragma('vm:never-inline')
  int get inMilliseconds => _value ~/ 1000;

  @pragma('vm:never-inline')
  int get inMicroseconds => _value;
}
