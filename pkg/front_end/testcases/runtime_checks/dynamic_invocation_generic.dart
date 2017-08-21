// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

class C<T> {
  void f< /*@checkFormal=semiSafe*/ U extends T>(U x) {}
}

void g1(dynamic d) {
  d.f<num> /*@checkCall=dynamic*/ (1.5);
}

void g2(dynamic d) {
  d.f /*@checkCall=dynamic*/ (1.5);
}

void test() {
  g1(new C<int>());
  g2(new C<int>());
}

main() {}
