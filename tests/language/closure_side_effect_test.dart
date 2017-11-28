// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

var b;
var a = () {
  b = 42;
};

var c = [new C()];

class C {
  nonInlinable1() {
    a();
  }

  nonInlinable2() {
    var a = () {
      b = 42;
    };
    a();
  }
}

testClosureInStaticField() {
  var temp = c[0];
  Expect.isNull(b);
  temp.nonInlinable1();
  Expect.equals(42, b);
  b = null;
}

testLocalClosure() {
  var temp = c[0];
  Expect.isNull(b);
  temp.nonInlinable2();
  Expect.equals(42, b);
}

main() {
  testClosureInStaticField();
  testLocalClosure();
}
