// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Operator dart test program.

import "package:expect/expect.dart";

class Helper {
  int i;
  Helper(int val) : i = val {}
  operator [](int index) {
    return i + index;
  }

  void operator []=(int index, int val) {
    i = val;
  }
}

main() {
  Helper obj = new Helper(10);
  Expect.equals(10, obj.i);
  obj[10] = 20;
  Expect.equals(30, obj[10]);

  regress32754();
}

// Regression test for https://github.com/dart-lang/sdk/issues/32754
class C {
  operator []=(i, value) {
    value = 'OOPS';
  }
}

class C2 {
  int data;
  operator []=(i, value) {
    // The return expression must be evaluated, then ignored.
    return () {
      data = i + value;
      return null;
    }();
  }
}

regress32754() {
  var c = new C();
  Expect.equals('ok', c[0] = 'ok');

  var c2 = new C2();
  Expect.equals(23, c2[100] = 23);
  Expect.equals(123, c2.data);
}
