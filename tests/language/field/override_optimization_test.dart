// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  final dynamic flag = true;
  final dynamic x = 42;
}

class B extends A {
  dynamic flag;
  dynamic x;
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
  } catch (e) {
    exception = e;
  }
  Expect.isTrue(exception is AssertionError || exception is TypeError);
  Expect.throws(() => a.x + 8);
}
