// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing the instanceof operation.
// Regression test for issue 5216.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr --no-background-compilation

import "package:expect/expect.dart";

class Foo<T> {
  bool isT() => "a string" is T;
  bool isNotT() => "a string" is! T;
  bool isListT() => [0, 1, 2] is List<T>;
  bool isNotListT() => [0, 1, 2] is! List<T>;
  bool isAlsoListT() => <int>[0, 1, 2] is List<T>;
  bool isNeitherListT() => <int>[0, 1, 2] is! List<T>;
}

testFooString() {
  var o = new Foo<String>();
  Expect.isTrue(o.isT());
  Expect.isTrue(!o.isNotT());
  Expect.isTrue(!o.isListT());
  Expect.isTrue(o.isNotListT());
  Expect.isTrue(!o.isAlsoListT()); // //# 01: ok
  Expect.isTrue(o.isNeitherListT()); // //# 01: ok
  for (var i = 0; i < 20; i++) {
    // Make sure methods are optimized.
    o.isT();
    o.isNotT();
    o.isListT();
    o.isNotListT();
    o.isAlsoListT(); // //# 01: ok
    o.isNeitherListT(); // //# 01: ok
  }
  Expect.isTrue(o.isT(), "1");
  Expect.isTrue(!o.isNotT(), "2");
  Expect.isTrue(!o.isListT(), "3");
  Expect.isTrue(o.isNotListT(), "4");
  Expect.isTrue(!o.isAlsoListT(), "5"); // //# 01: ok
  Expect.isTrue(o.isNeitherListT(), "6"); // //# 01: ok
}

testFooInt() {
  var o = new Foo<int>();
  Expect.isTrue(!o.isT());
  Expect.isTrue(o.isNotT());
  Expect.isTrue(o.isListT());
  Expect.isTrue(!o.isNotListT());
  Expect.isTrue(o.isAlsoListT());
  Expect.isTrue(!o.isNeitherListT());
  for (var i = 0; i < 20; i++) {
    // Make sure methods are optimized.
    o.isT();
    o.isNotT();
    o.isListT();
    o.isNotListT();
    o.isAlsoListT();
    o.isNeitherListT();
  }
  Expect.isTrue(!o.isT());
  Expect.isTrue(o.isNotT());
  Expect.isTrue(o.isListT());
  Expect.isTrue(!o.isNotListT());
  Expect.isTrue(o.isAlsoListT());
  Expect.isTrue(!o.isNeitherListT());
}

main() {
  testFooString();
  testFooInt();
}
