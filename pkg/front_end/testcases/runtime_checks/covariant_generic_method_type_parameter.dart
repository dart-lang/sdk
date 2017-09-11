// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

class C<T> {
  void f< /*@checkFormal=semiSafe*/ /*@checkInterface=semiTyped*/ U extends T>(
      U x) {}
  void
      g1< /*@checkFormal=semiSafe*/ /*@checkInterface=semiTyped*/ U extends T>() {
    this.f<U> /*@callKind=this*/ (1.5);
  }
}

void g2(C<Object> c) {
  c.f<num>(1.5);
}

void test() {
  new C<int>().g1<num>();
  g2(new C<int>());
}

void main() {}
