// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class NativeClass native "FooBar" {
  factory NativeClass() {
    return _createFooBar();
  }

  int foo(x, y) { return x + y + 499; }
  int bar(x, y) native;
  static toto(x, y) { return x - y + 499; }
  static NativeClass _createFooBar() native;
}


interface A {
  foo();
}

class NativeA implements A native "JSA" {
  factory NativeA() {
    return _new();
  }
  foo(){}

  static _new() native;
}

class NativeTest {
  static int counter;

  static int jsIncrementBy(x, y) native;

  static int dartIncrementBy(int x, int y) native {
    counter += x + y;
    return counter;
  }

  static void testRoundTrip() {
    counter = 0;
    var passedThrough = jsIncrementBy(3, 4);
    assert(passedThrough == 7);
    assert(counter == 7);
  }

  static void testNativeClass() {
    assert(NativeClass.toto(1, 1) == 499);
    NativeClass nc = new NativeClass();
    assert(nc is NativeClass);
    assert(nc.foo(1, 524) == 1024);
    assert(nc.bar(1, 499) == -1);
    NativeA na = new NativeA();
    assert(na is NativeA);
    assert(na is A);
  }
}

main() {
  NativeTest.testRoundTrip();
  NativeTest.testNativeClass();
}
