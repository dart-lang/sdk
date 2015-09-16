// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class X {
  call() => 42;
}

class Y {
  call(int x) => 87;
}

typedef F(int x);
typedef G(String y);

main() {
  X x = new X();
  Function f = x;  // Should pass checked mode test
  Y y = new Y();
  Function g = y;  // Should pass checked mode test
  F f0 = y;  // Should pass checked mode test
  F f1 = x;  /// 00: dynamic type error, static type warning
  G g0 = y;  /// 01: dynamic type error, static type warning
}

