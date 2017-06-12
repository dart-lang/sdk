// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:meta/meta.dart";

class A {
  @virtual
  final bool flag = true;
  @virtual
  final int x = 42;
}

class B extends A {
  bool flag;
  int x;
}

void main() {
  A a = new B();
  var exception;
  try {
    if (a.flag) {
      Expect.fail('This should be unreachable');
    } else {
      Expect.fail('This should also be unreachable');
    }
  } on AssertionError catch (e) {
    exception = e;
  }
  Expect.isTrue(exception is AssertionError);
  Expect.throws(() => a.x + 8);
}
