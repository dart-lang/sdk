// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

class C {
  void set x(dynamic value) {}
  dynamic y;
  void test() {
    // Set via this
    /*@callKind=this*/ x = null;
    this. /*@callKind=this*/ x = null;
    /*@callKind=this*/ y = null;
    this. /*@callKind=this*/ y = null;
  }
}

void test(C c, dynamic d) {
  // Set via interface
  c.x = null;
  c.y = null;

  // Dynamic set
  d. /*@callKind=dynamic*/ x = null;
}

main() {}
