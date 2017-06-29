// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class C {}

class D extends C {}

class E extends StackTrace {}

void test(void f()) {
  try {
    f();
  } on C catch (x, y) {
    var /*@type=C*/ x1 = x;
    var /*@type=StackTrace*/ y1 = y;
    if (x is D) {
      var /*@type=D*/ x2 = /*@promotedType=D*/ x;
    }
    if (y is E) {
      var /*@type=E*/ y2 = /*@promotedType=E*/ y;
    }
  }
}

main() {}
