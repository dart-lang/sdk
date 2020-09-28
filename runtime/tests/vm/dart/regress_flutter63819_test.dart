// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that 'is' test of a nullable type accepts null.
// Regression test for https://github.com/flutter/flutter/issues/63819.

import 'package:expect/expect.dart';

abstract class A {}

class B extends A {}

class C extends A {}

@pragma('vm:never-inline')
bool foo(A? x) {
  if (x is C?) {
    print('$x is C?');
    return true;
  }
  print('$x is not C?');
  return false;
}

void main() {
  B();
  C();
  Expect.isFalse(foo(B()));
  Expect.isTrue(foo(null));
}
