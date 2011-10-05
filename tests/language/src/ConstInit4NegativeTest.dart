// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing circular initialization errors.

class K {
  static final n = 1;
  static final p = const P(n, 0);
}

class P {
  const P(this._x, this._y) : _p = K.p;
  final _x;
  final _y;
  final _p;
}

class ConstInit4NegativeTest {
  static testMain() {
    var x = K.p;
  }
}

main() {
  ConstInit4NegativeTest.testMain();
}
