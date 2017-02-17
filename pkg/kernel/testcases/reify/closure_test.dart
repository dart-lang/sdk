// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library closure_test;

import 'test_base.dart';

class A {}

class B {}

typedef B A2B(A a);
typedef A B2A(B b);

bar(A a) {
  return null;
}

B baz(a) {
  return null;
}

main() {
  B foo(A a) {
    return null;
  }

  A qux(B b) {
    return null;
  }

  expectTrue(foo is A2B);
  expectTrue(qux is! A2B);
  expectTrue(foo is! B2A);
  expectTrue(qux is B2A);

  expectTrue(bar is A2B);
  expectTrue(bar is! B2A);
  expectTrue(baz is A2B);
  expectTrue(baz is! B2A);

  var rab = bar;
  var zab = baz;
  expectTrue(rab is A2B);
  expectTrue(rab is! B2A);
  expectTrue(zab is A2B);
  expectTrue(zab is! B2A);
}
