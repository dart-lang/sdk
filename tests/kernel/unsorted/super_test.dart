// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class A {
  var field = 9;
  var called = false;

  superMethod() {
    Expect.isTrue(field == 10);
    called = true;
    return true;
  }
}

class B extends A {
  doit() {
    Expect.isTrue((super.field = 10) == 10);
    Expect.isTrue(super.superMethod());
    if (called) {
      Expect.isTrue((super.field = 11) == 11);
    }
    return super.field;
  }
}

class C extends B {
  set field(v) {
    throw 'should not happen';
  }
}

main() {
  var c = new C();
  Expect.isTrue(c.field == 9);
  Expect.isTrue(c.doit() == 11);
  Expect.isTrue(c.field == 11);
}
