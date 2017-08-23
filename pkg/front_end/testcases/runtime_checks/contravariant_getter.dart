// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

typedef void F<T>(T x);

class C<T> {
  F<T> y;
  void f(T /*@checkFormal=semiSafe*/ value) {
    this.y /*@checkCall=interface(semiTyped:0)*/ (value);
  }
}

void g(/*safe*/ C<num> c) {
  c. /*@checkReturn=(num) -> void*/ y /*@checkCall=interface(semiTyped:0)*/ (
      1.5);
}

void main() {}
