// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

typedef void F<T>(T x);
typedef F<T> G<T>();

class C<T> {
  F<T> /*@genericContravariant=true*/ _x;
  C(this._x);
  F<T> /*@genericContravariant=true*/ f() => /*@callKind=this*/ _x;
}

G<num> g(C<num> c) {
  return c. /*@checkReturn=() -> (num) -> void*/ f;
}

void h(int i) {
  print('$i');
}

void test() {
  var x = g(new C<int>(h));
}

void main() {}
