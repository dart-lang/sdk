// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that Object.dynamic returns the identical object.

main() {
  // Primitives
  var anInt = 5;
  var aString = 'Hello';
  var aBool = true;
  var aDouble = 3.14159;

  // Compounds
  var aMap = {};

  // The type should not change.
  Expect.isTrue(dyn(anInt) is int, 'is int');
  Expect.isTrue(dyn(aString) is String, 'is String');
  Expect.isTrue(dyn(aBool) is bool, 'is bool');
  Expect.isTrue(dyn(aMap) is Map, 'is Map');

  // The object should be identical.
  Expect.isTrue(eq(anInt, anInt.dynamic), 'anInt.dynamic');
  Expect.isTrue(eq(aString, aString.dynamic), 'aString.dynamic');
  Expect.isTrue(eq(aBool, aBool.dynamic), 'aBool.dynamic');
  Expect.isTrue(eq(aDouble, aDouble.dynamic), 'aDouble.dynamic');
  Expect.isTrue(eq(aMap, aMap.dynamic), 'aMap.dynamic');
}

dyn(x) => x.dynamic;

eq(a, b) => a === b;
