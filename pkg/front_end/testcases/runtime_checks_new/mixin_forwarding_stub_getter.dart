// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

typedef void F<T>(T t);

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
  F<int> get x {
    throw 'Should not be reached';
  }

  void set x(Object value) {
    throw 'Should not be reached';
  }
}

abstract class I<T> {
  F<T> get x;
  void set x(Object value);
}

abstract class M<T> {
  T get x => f();
  void set x(Object value) {
    throw 'Should not be reached';
  }

  T f();
}

abstract class C<T> = B with M<F<T>> implements I<T>;

class D extends C<int> {
  F<int> f() => (int i) {
        expect(i, 1);
      };
}

void test(I<Object> iObj, I<int> iInt) {
  expectTypeError(() {
    // iObj.x is expected to return type (Object) -> void, but it returns
    // (int) -> void (which is a supertype of (Object) -> void), so that's a
    // type error.
    var x = iObj. /*@checkReturn=(Object) -> void*/ x;
  });
  // iInt.x is expected to return type (int) -> void, and it does.
  var x = iInt. /*@checkReturn=(int) -> void*/ x;
  x(1);
}

void main() {
  var d = new D();
  test(d, d);
}
