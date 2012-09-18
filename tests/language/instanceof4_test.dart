// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing the instanceof operation.
// Regression test for issue 5216.

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
  Expect.isTrue(o.isListT());
  Expect.isTrue(!o.isNotListT());
  Expect.isTrue(!o.isAlsoListT());
  Expect.isTrue(o.isNeitherListT());
  for (var i = 0; i < 4000; i++) {
    // Make sure methods are optimized.
    o.isT();
    o.isNotT();
    o.isListT();
    o.isNotListT();
    o.isAlsoListT();
    o.isNeitherListT();
  }
  Expect.isTrue(o.isT());
  Expect.isTrue(!o.isNotT());
  Expect.isTrue(o.isListT());
  Expect.isTrue(!o.isNotListT());
  Expect.isTrue(!o.isAlsoListT());
  Expect.isTrue(o.isNeitherListT());
}

testFooInt() {
  var o = new Foo<int>();
  Expect.isTrue(!o.isT());
  Expect.isTrue(o.isNotT());
  Expect.isTrue(o.isListT());
  Expect.isTrue(!o.isNotListT());
  Expect.isTrue(o.isAlsoListT());
  Expect.isTrue(!o.isNeitherListT());
  for (var i = 0; i < 4000; i++) {
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
