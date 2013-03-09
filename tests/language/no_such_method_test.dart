// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program testing that NoSuchMethod is properly called.

class NoSuchMethodTest {

  foo({a : 10, b : 20}) {
    return (10 * a) + b;
  }

  noSuchMethod(InvocationMirror im) {
    Expect.equals("moo", im.memberName);
    Expect.equals(0, im.positionalArguments.length);
    Expect.equals(1, im.namedArguments.length);
    return foo(b:im.namedArguments["b"]);
  }

  static testMain() {
    var obj = new NoSuchMethodTest();
    Expect.equals(199, obj.moo(b:99));  // obj.NoSuchMethod called here.
  }
}

main() {
  NoSuchMethodTest.testMain();
}
