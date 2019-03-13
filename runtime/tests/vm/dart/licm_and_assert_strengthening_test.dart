// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

// This test checks for obscure interaction between LICM and AssertAssignable
// strengthening performed by Type Propagator. The later would use deopt_id
// from an environment attached to AssertAssignable, and this deopt id under
// certain conditions would be set to -1. The code was changed to never
// use deopt_id from the environment but this regression test is provided for
// completeness.

class A<T> {
  var foo = 42;
}

class B extends A<String> {}

class C extends B {}

void foo(dynamic a) {
  // To prevent AssertAssignable strengthening from occuring too early we
  // need to hide the fact that CheckClass and AssertAssignable are performed
  // against the same SSA value. To achieve that we store a into an array and
  // then load it back. Load Forwarding would happen just before LICM and
  // will remove the indirection. Then LICM would hoist both CheckClass
  // and AssertAssignable out of the loop and then strengthening would happen.
  final box = <dynamic>[null];
  box[0] = a;

  for (var i = 0; i < 1; i++) {
    a as A<String>;
    if (box[0].foo != 42) {
      throw "unexpected";
    }
  }
}

void main() {
  for (var i = 0; i < 100; i++) {
    foo(B());
  }

  // Trigger deoptimization on the CheckClass produced by strengthened
  // AssertAssignable - if this CheckClass has wrong deoptimization id a crash
  // would occur.
  foo(C());
}
