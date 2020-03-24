// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

class Foo {
  int f() => 42;
}

class Bar extends Foo {
  void test() {
    Expect.isFalse(super.f is int);
  }
}

void main() {
  Bar().test();
}
