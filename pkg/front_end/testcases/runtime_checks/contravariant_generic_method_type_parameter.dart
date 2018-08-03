// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

typedef void F<T>(T t);

class C<T> {
  void f<U extends F<T>>(U x) {}
}

void g(C<num> c) {
  c.f<F<Object>>((Object o) {});
}

void test() {
  g(new C<int>());
}

void main() {}
