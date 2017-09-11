// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

typedef void F<T>(T x);

class C<T> {
  F<T> f1() {}
  List<F<T>> f2() {
    return [this.f1 /*@callKind=this*/ ()];
  }
}

void g1(C<num> c) {
  var x = c.f1 /*@checkReturn=(num) -> void*/ ();
  print('hello');
  x /*@callKind=closure*/ (1.5);
}

void g2(C<num> c) {
  F<int> x = c.f1 /*@checkReturn=(num) -> void*/ ();
  x /*@callKind=closure*/ (1);
}

void g3(C<num> c) {
  var x = c.f2 /*@checkReturn=List<(num) -> void>*/ ();
}

void main() {}
