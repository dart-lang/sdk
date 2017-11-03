// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

void expectTypeError(void callback()) {
  try {
    callback /*@callKind=closure*/ ();
    throw 'Expected TypeError, did not occur';
  } on TypeError {}
}

void expect(Object value, Object expected) {
  if (value != expected) {
    throw 'Expected $expected, got $value';
  }
}

class C<T> {
  C(this.plusResult);
  final num Function(T) /*@genericContravariant=true*/ plusResult;
  num Function(T) operator /*@genericContravariant=true*/ +(
      int i) => /*@callKind=this*/ plusResult;
}

class D {
  D(this.getValue);
  final C<num> getValue;
  C<num> get value => /*@callKind=this*/ getValue;
  int Function(int) setValue;
  void set value(int Function(int) value) {
    setValue = value;
  }
}

int numToInt(num n) => 1;

num numToNum(num n) => 2;

void main() {
  // d.value += 1 desugars to:
  //   d.value = (c.operator+(1) as (num)->num) as (int)->int
  // So it should be ok for c.operator+(1) to return this type:
  //   (num)->int
  // But not this one:
  //   (num)->num
  D d = new D(new C(numToInt));
  d.value /*@checkReturn=(num) -> num*/ += 1;
  expect(d.setValue /*@callKind=closure*/ (0), 1);
  d = new D(new C(numToNum));
  expectTypeError(() {
    d.value /*@checkReturn=(num) -> num*/ += 1;
  });
  expect(d.setValue, null);
}
