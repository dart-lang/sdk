// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Regression test for https://github.com/dart-lang/sdk/issues/29733 in DDC.
foo(a) {
  var a = 123;
  return a;
}

// Regression test for https://github.com/dart-lang/sdk/issues/30792 in DDC.
bar(a) async {
  var a = 123;
  return a;
}

baz(a) sync* {
  var a = 123;
  yield a;
}

qux(a) async* {
  var a = 123;
  yield a;
}

// Regression test for https://github.com/dart-lang/sdk/issues/32140
class C {
  var x, y, localY, _value;

  C(a) {
    var a = 123;
    this.x = a;
  }

  C.initY(this.y) {
    var y = 123;
    this.localY = y;
  }

  method(a) {
    var a = 123;
    return a;
  }

  get accessor => _value;
  set accessor(a) {
    var a = 123;
    this._value = a;
  }
}

testCatch() {
  try {
    throw 'oops';
  } catch (e) {
    var e = 123;
    return e;
  }
}

testStackTrace() {
  try {
    throw 'oops';
  } catch (e, s) {
    var s = 123;
    return s;
  }
}

main() async {
  Expect.equals(foo(42), 123);
  Expect.equals(await bar(42), 123);
  Expect.equals(baz(42).single, 123);
  Expect.equals(await qux(42).single, 123);

  var c = new C('hi');
  Expect.equals(c.x, 123);
  Expect.equals(c.method(42), 123);
  c.accessor = 42;
  Expect.equals(c.accessor, 123);
  c = new C.initY(42);
  Expect.equals(c.y, 42);
  Expect.equals(c.localY, 123);

  Expect.equals(testCatch(), 123);
  Expect.equals(testStackTrace(), 123);
}
