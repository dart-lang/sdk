// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

typedef void F<T>(T x);

class C<T> {
  F<T> get f1 => null;
  List<F<T>> get f2 {
    return [this?. /*@callKind=this*/ f1];
  }
}

void g1(C<num> c) {
  var x = c?. /*@checkReturn=(num) -> void*/ f1;
  print('hello');
  x /*@callKind=closure*/ (1.5);
}

void g2(C<num> c) {
  F<int> x = c?. /*@checkReturn=(num) -> void*/ f1;
  x /*@callKind=closure*/ (1);
}

void g3(C<num> c) {
  var x = c?. /*@checkReturn=List<(num) -> void>*/ f2;
}

void main() {}
