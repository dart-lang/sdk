// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

var field;

class Class {
  @pragma('dart2js:noInline')
  method(int i, int j, int k) {}
}

@pragma('dart2js:noInline')
test1(dynamic c, num n) {
  if (c is Class) {
    c.method(field = 41, n, field = 42);
  }
}

@pragma('dart2js:noInline')
test2(dynamic c, num n) {
  if (c is! Class) return;
  c.method(field = 86, n, field = 87);
}

main() {
  try {
    test1(new Class(), 0.5);
    field = 123;
    field = 123;
  } catch (e) {}
  // CFE inserts the implicit cast directly on the argument expression, making
  // it fail before later arguments are evaluated.
  Expect.equals(41, field);

  try {
    test2(new Class(), 0.5);
    field = 321;
    field = 321;
  } catch (e) {}
  // dart2js inserts implicit casts, but does so after evaluating all arguments
  // to ensure semantics match what it would be like to check the types when
  // entering the callee.
  Expect.equals(87, field);
}
