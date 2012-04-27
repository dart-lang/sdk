// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program testing that NoSuchMethod is properly called.

class NoSuchMethodTest {

  foo([a = 10, b = 20]) {
    return (10 * a) + b;
  }

  noSuchMethod(String name, List args) {
    Expect.equals("moo", name);
    Expect.equals(1, args.length);
    return foo(args[0]);
  }

  static testMain() {
    var obj = new NoSuchMethodTest();
    Expect.equals(1010, obj.moo(b:99));  // obj.NoSuchMethod called here.
    // After we remove the rest argument and change the signature of
    // noSuchMethod to be compatible with named arguments, we can expect the
    // correct value of 199 instead of 1010.
  }
}

main() {
  NoSuchMethodTest.testMain();
}
