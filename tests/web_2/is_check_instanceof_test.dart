// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

// It is sometimes possible to compile is-checks to 'instanceof', when the class
// is not in an 'implements' clause or used as a mixin.

// This test verifies is-checks work with simple classes that have various
// degrees of instantiation.

class INSTANTIATED {} // instantiated and used in many ways

class DEFERRED {} // instantiated after first check

class UNUSED {} // used only in is-check

class REMOVED {} // allocated but optimized out of program

class DEFERRED_AND_REMOVED {} // allocated after first check and removed

class USED_AS_TYPE_PARAMETER {} // only used as a type parameter

class USED_AS_TESTED_TYPE_PARAMETER {} // only used as a type parameter

class Check<T> {
  bool check(x) => x is T;
}

class Check2<T> {
  bool check(x) => x is USED_AS_TYPE_PARAMETER;
}

void main() {
  var things = new List(3);
  things.setRange(0, 3, [new INSTANTIATED(), 1, new Object()]);

  var checkX = new Check<INSTANTIATED>();
  var checkU1 = new Check<USED_AS_TESTED_TYPE_PARAMETER>();
  var checkU2 = new Check<USED_AS_TYPE_PARAMETER>();

  var removed = new REMOVED(); // This is optimized out.

  // Tests that can be compiled to instanceof:
  Expect.isTrue(things[0] is INSTANTIATED);
  Expect.isFalse(things[1] is INSTANTIATED);
  Expect.isFalse(things[1] is REMOVED);
  Expect.isFalse(things[1] is DEFERRED_AND_REMOVED);
  Expect.isFalse(things[1] is DEFERRED);
  // Tests that might be optimized to false since there are no allocations:
  Expect.isFalse(things[1] is UNUSED);
  Expect.isFalse(things[1] is USED_AS_TYPE_PARAMETER);

  Expect.isTrue(checkX.check(things[0]));
  Expect.isFalse(checkX.check(things[1]));
  Expect.isFalse(checkU1.check(things[1]));
  Expect.isFalse(checkU2.check(things[1]));

  var removed2 = new DEFERRED_AND_REMOVED(); // This is optimized out.

  // First allocation of DEFERRED is after the above tests.
  things.setRange(0, 3, [new INSTANTIATED(), 1, new DEFERRED()]);

  // Tests that can be compiled to instanceof:
  Expect.isTrue(things[0] is INSTANTIATED);
  Expect.isFalse(things[1] is INSTANTIATED);
  Expect.isFalse(things[1] is REMOVED);
  Expect.isFalse(things[1] is DEFERRED_AND_REMOVED);
  Expect.isFalse(things[1] is DEFERRED);
  Expect.isTrue(things[2] is DEFERRED);
  // Tests that might be optimized to false since there are no allocations:
  Expect.isFalse(things[1] is UNUSED);
  Expect.isFalse(things[1] is USED_AS_TYPE_PARAMETER);
}
