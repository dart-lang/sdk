// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int callCount = 0;

abstract class A<X> {
  void Function(X) get g;
}

class B implements A<int> {
  void Function(int) get g => (int i) => callCount++;
}

void foo(Object o, num value) {
  switch (o) {
    case B(g: _) && A<num>(g: var f):
      f(value);
  }
}

void main() {
  expect(0, callCount);
  throws(() => foo(B(), 25.7));
  expect(0, callCount);
  throws(() => foo(B(), 1));
  expect(0, callCount);
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Expected $expected, actual $actual';
  }
}

throws(void Function() f) {
  try {
    f();
  } catch (e) {
    print(e);
    return;
  }
  throw 'No exception thrown';
}
