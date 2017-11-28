// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

class C {
  dynamic get x => null;
  dynamic y;
  void test() {
    // Get via this
    var v1 = /*@callKind=this*/ x;
    var v2 = this. /*@callKind=this*/ x;
    var v3 = /*@callKind=this*/ y;
    var v4 = this. /*@callKind=this*/ y;
  }
}

void test(C c, dynamic d) {
  // Get via interface
  var v1 = c.x;
  var v2 = c.y;

  // Dynamic get
  var v3 = d. /*@callKind=dynamic*/ x;
}

main() {}
