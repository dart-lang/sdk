// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test canonicalization of integer shift operations.
// This is a regression test for dartbug.com/34288.

// VMOptions=--no_background_compilation --optimization_counter_threshold=10

import "package:expect/expect.dart";

int _shl_63(int x) => x << 63;
int _shl_64(int x) => x << 64;
int _shl_65(int x) => x << 65;
int _shl_m1(int x) => x << -1;

int _shr_63(int x) => x >> 63;
int _shr_64(int x) => x >> 64;
int _shr_65(int x) => x >> 65;
int _shr_m1(int x) => x >> -1;

// Non-constant values.
int one = 1;
int minusOne = -1;

doTests() {
  Expect.equals(0x8000000000000000, _shl_63(one));
  Expect.equals(0x8000000000000000, _shl_63(minusOne));
  Expect.equals(0, _shl_64(one));
  Expect.equals(0, _shl_64(minusOne));
  Expect.equals(0, _shl_65(one));
  Expect.equals(0, _shl_65(minusOne));

  Expect.throws<ArgumentError>(() {
    _shl_m1(one);
  });

  Expect.equals(0, _shr_63(one));
  Expect.equals(-1, _shr_63(minusOne));
  Expect.equals(0, _shr_64(one));
  Expect.equals(-1, _shr_64(minusOne));
  Expect.equals(0, _shr_65(one));
  Expect.equals(-1, _shr_65(minusOne));

  Expect.throws<ArgumentError>(() {
    _shr_m1(one);
  });
}

void main() {
  for (int i = 0; i < 20; ++i) {
    doTests();
  }
}
