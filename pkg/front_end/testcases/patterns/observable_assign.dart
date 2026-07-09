// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  get b => throw 'foo';
}

class B extends A {
  get b => 42;
}

method1((A, A) r) {
  var b1;
  var b2;
  (A(b: b1), A(b: b2)) = r;
  return b1;
}

method2((A, A) r) {
  var b1;
  var b2;
  try {
    (A(b: b1), A(b: b2)) = r;
  } catch (_) {}
  return b1;
}

method3((A, A) r) {
  var b1;
  var b2;
  allowThrow(() {
    (A(b: b1), A(b: b2)) = r;
  });
  return b1;
}

method4((A, A) r) {
  var b1;
  var b2;
  local() {
    (A(b: b1), A(b: b2)) = r;
  }

  allowThrow(local);
  return b1;
}

main() {
  throws(() => method1((B(), A())));
  expect(null, method2((B(), A())));
  expect(null, method3((B(), A())));
  expect(null, method4((B(), A())));
  expect(42, method1((B(), B())));
  expect(42, method2((B(), B())));
  expect(42, method3((B(), B())));
  expect(42, method4((B(), B())));
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}

throws(void Function() f) {
  try {
    f();
  } catch (_) {
    return;
  }
  throw 'Missing throw';
}

allowThrow(void Function() f) {
  try {
    f();
  } catch (_) {}
}
