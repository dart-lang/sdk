// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import "package:expect/expect.dart";

class C {
  T foo<T>(T value) => value;
}

void main() {
  var c = C();
  num Function(num) f0 = c.foo;
  int Function(int) f1 = c.foo;
  Expect.notEquals(f0, f1);
}
