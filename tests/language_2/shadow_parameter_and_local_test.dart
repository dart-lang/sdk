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

  mOptional([a = 0]) {
    var a = 123;
    return a;
  }

  mNamed({a = 0}) {
    var a = 123;
    return a;
  }

  mAsync({a: 0}) async {
    var a = 123;
    return a;
  }

  mSyncStar({a: 0}) sync* {
    var a = 123;
    yield a;
  }

  mAsyncStar({a: 0}) async* {
    var a = 123;
    yield a;
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
  Expect.equals(123, foo(42));
  Expect.equals(123, await bar(42));
  Expect.equals(123, baz(42).single);
  Expect.equals(123, await qux(42).single);

  await testClass();

  Expect.equals(123, testCatch());
  Expect.equals(123, testStackTrace());
}

testClass() async {
  var c = new C('hi');
  Expect.equals(123, c.x);
  Expect.equals(123, c.method(42));
  c.accessor = 42;
  Expect.equals(123, c.accessor);
  c = new C.initY(42);
  Expect.equals(42, c.y);
  Expect.equals(123, c.localY);

  Expect.equals(123, c.mOptional());
  Expect.equals(123, c.mOptional(42));

  Expect.equals(123, c.mNamed());
  Expect.equals(123, c.mNamed(a: 42));

  Expect.equals(123, await c.mAsync());

  var iter = c.mSyncStar();
  Expect.listEquals([123], iter.toList());
  Expect.listEquals([123], iter.toList(), 'second iteration yields same value');

  var stream = c.mAsyncStar();
  Expect.listEquals([123], await stream.toList());
}
