// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

class C {
  dynamic f;
  C(this.f);
}

void g(C c) {
  c.f /*@callKind=dynamic*/ (1.5);
}

void h(int i) {}
void test() {
  g(new C(h));
}

main() {}
