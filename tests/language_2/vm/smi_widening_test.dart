// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--deterministic --optimization-counter-threshold=102 --enable-inlining-annotations --optimization-filter=Box_

import 'package:expect/expect.dart';

const String NeverInline = 'NeverInline';
const String AlwaysInline = 'AlwaysInline';
const int kLimit = 100;

main() {
  // Get all 3 functions optimized with _Smi's.
  optimizeMilliseconds(1);
  optimizeMicroseconds(1);
  optimizeConstructor(1);

  // Now we trigger a store of a _Mint into the Box._value
  testMints(2048);
}

@NeverInline
optimizeConstructor(int value) {
  for (int i = 0; i < kLimit; ++i) {
    new Box(milliseconds: value);
  }
}

@NeverInline
optimizeMicroseconds(int value) {
  final d = new Box(milliseconds: value);
  for (int i = 0; i < kLimit; ++i) {
    Expect.equals(value * 1000, d.inMicroseconds);
  }
}

@NeverInline
optimizeMilliseconds(int value) {
  final d = new Box(seconds: value);
  for (int i = 0; i < kLimit; ++i) {
    Expect.equals(value * 1000, d.inMilliseconds);
  }
}

@NeverInline
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

  @NeverInline
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

  @NeverInline
  int get inMilliseconds => _value ~/ 1000;

  @NeverInline
  int get inMicroseconds => _value;
}
