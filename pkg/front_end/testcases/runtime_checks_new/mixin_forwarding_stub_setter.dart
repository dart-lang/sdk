// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

void expectTypeError(void callback()) {
  try {
    callback();
    throw 'Expected TypeError, did not occur';
  } on TypeError {}
}

void expect(Object value, Object expected) {
  if (value != expected) {
    throw 'Expected $expected, got $value';
  }
}

class B {
  int get x {
    throw 'Should not be reached';
  }

  void set x(int value) {
    throw 'Should not be reached';
  }

  int get y {
    throw 'Should not be reached';
  }

  void set y(int value) {
    throw 'Should not be reached';
  }
}

abstract class I<T> {
  T get x;
  void set x(T value);
  Object get y;
  void set y(covariant Object value);
}

class M {
  int get x => 1;
  void set x(int value) {
    expect(value, 2);
  }

  int get y => 3;
  void set y(int value) {
    expect(value, 4);
  }
}

class C = B with M implements I<int>;

void test(I<Object> i) {
  expectTypeError(() {
    i.x = 'hello';
  });
  i.x = 2;
  expect(i.x, 1);
  expectTypeError(() {
    i.y = 'hello';
  });
  i.y = 4;
  expect(i.y, 3);
}

void main() {
  test(new C());
}
