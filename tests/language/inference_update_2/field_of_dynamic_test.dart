// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that field accesses applied to a `dynamic` type are not promoted even
// if the only thing they could possibly resolve to is promotable.
//
// The rationale for this behavior is that if we allowed accesses on `dynamic`
// to be promoted under such circumstances, then the addition of *any* class
// containing an implementation of `noSuchMethod` other than the one from
// `Object` would violate soundness. (See `field_of_dynamic_with_nsm_test.dart`
// for a concrete example of this).

// SharedOptions=--enable-experiment=inference-update-2

class C {
  final Object? _x;
  C(this._x);
}

void testDynamicInvocation(dynamic d) {
  if (d._x is int) {
    // `d._x` should not be promoted to `int`. To verify that it still has type
    // `dynamic`, we try to call a method that doesn't exist on `int`.
    d._x.nonExistentMethod();
  }
}

main() {
  testDynamicInvocation(C('not an int'));
}
