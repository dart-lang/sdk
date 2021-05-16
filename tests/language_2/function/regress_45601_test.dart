// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import "package:expect/expect.dart";

// Regression test for https://github.com/dart-lang/sdk/issues/45601
// When comparing values of type `Function` for equality DDC was generating
// code that would throw at runtime.

void fn<T>(T t) => null;

void main() {
  testStaticEquality();
  testDynamicEquality();
}

/// Ensure `==` calls on function values that are statically typed as `Function`
/// work as expected.
void testStaticEquality() {
  Function staticFunction = fn;
  Expect.isTrue(staticFunction == fn);
  Expect.isFalse(staticFunction == main);

  Function staticFunction2 = null;
  Expect.isFalse(staticFunction2 == staticFunction);
  staticFunction2 = fn;
  Expect.isTrue(staticFunction2 == staticFunction);
}

/// Ensure `==` calls on function values that are statically typed as `dynamic`
/// work as expected.
void testDynamicEquality() {
  dynamic dynamicFunction = fn;
  Expect.isTrue(dynamicFunction == fn);
  Expect.isFalse(dynamicFunction == main);

  dynamic dynamicFunction2 = null;
  Expect.isFalse(dynamicFunction2 == dynamicFunction);
  dynamicFunction2 = fn;
  Expect.isTrue(dynamicFunction2 == dynamicFunction);
}
