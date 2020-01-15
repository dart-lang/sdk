// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

/*@testedFeatures=checks*/

class A<T extends num> {
  void Function<S extends T>(S x) foo() {
    print('foo: T = $T');
    return <S extends T>(S a) {};
  }
}

class B<T extends num> {
  void Function(T x) foo() {
    print('foo: T = $T');
    return (T a) {};
  }
}

A<num> a = new A<int>();
B<num> b = new B<int>();

main() {
  try {
    a.foo /*@ checkReturn=<S extends num* = dynamic>(S*) ->* void */ ();
    throw 'Expected TypeError';
  } on TypeError catch (e) {
    print(e);
  }
  try {
    b.foo /*@ checkReturn=(num*) ->* void */ ();
    throw 'Expected TypeError';
  } on TypeError catch (e) {
    print(e);
  }
}
