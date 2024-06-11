// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Class methods and getters and setters can still be named `_`.

// SharedOptions=--enable-experiment=wildcard-variables

import 'package:expect/expect.dart';

class A<_> {
  int _<_ extends num>([int _ = 2]) => 1;
}

class B {
  int x = 1;

  int get _ => x;
  void set _(int y) {
    x = y;
  }
}

void main() {
  var a = A();
  Expect.equals(1, a._());

  var b = B();
  Expect.equals(1, b._);
  b._ = 2;
  Expect.equals(2, b._);
}
