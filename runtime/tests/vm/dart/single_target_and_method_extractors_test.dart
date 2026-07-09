// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Note: below we are using tear-offs instead of calling methods directly
// to guarantee very specific compilation order:
//
//    - compile main, add get:methodM and get:callMethodM to selector set.
//    - compile A.callMethodM and add get:createB to selector set.
//    - compile A.createB and mark B as allocated.
//
// Class B is not marked as allocated until A.createB is compiled, which means
// that when A.callMethodM is compiled only class A has get:methodM method
// extractor injected.
//
// This test is verifying that optimizing compiler does not treat this method
// extractor as a single target for this.get:methodM call.
main() {
  // This adds selector 'get:methodM' into the sent selector set and
  // marks class A as allocated.
  new A().methodM;

  // This adds get:callMethodM to the sent selector set.
  final callMethodMOnA = new A().callMethodM;
  final b = callMethodMOnA("A");
  final callMethodMOnB = b.callMethodM;
  callMethodMOnB("B");
}

class A {
  B callMethodM(String expected) {
    final f = methodM;
    Expect.equals(expected, f());

    final newB = createB;
    return newB();
  }

  B createB() => new B();

  String methodM() => 'A';
}

class B extends A {
  @override
  String methodM() => 'B';
}
