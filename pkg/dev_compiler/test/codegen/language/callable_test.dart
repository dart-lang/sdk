// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class X {
  call() => 42;
}

class Y {
  call(int x) => 87 + x;

  static int staticMethod(int x) => x + 1;
}

class Z<T> {
  final T value;
  Z(this.value);
  call() => value;

  static int staticMethod(int x) => x + 1;
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

  Expect.equals(f(), 42);
  Expect.equals(g(100), 187);

  var z = new Z<int>(123);
  Expect.equals(z(), 123);
  // TODO(jmesserly): this test doesn't work yet.
  // Expect.equals((z as dynamic)(), 123);

  Expect.equals(Y.staticMethod(6), 7);
  Expect.equals(Z.staticMethod(6), 7);
}
