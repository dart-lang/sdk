// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class C {}

class D {}

class E {}

void test(void f()) {
  try {
    var /*@ type=int* */ x = 0;
    f();
  } on C {
    var /*@ type=int* */ x = 0;
  } on D catch (x) {
    var /*@ type=D* */ x2 = x;
  } on E catch (x, y) {
    var /*@ type=E* */ x2 = x;
    var /*@ type=StackTrace* */ y2 = y;
  } catch (x, y) {
    var /*@ type=dynamic */ x2 = x;
    var /*@ type=StackTrace* */ y2 = y;
  }
}

main() {}
