// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Regression test for https://github.com/dart-lang/sdk/issues/45601
// When comparing values of type `Function` for equality DDC was generating
// code that would throw at runtime.

class Wrapper {
  Wrapper(this.function);

  final Function function;

  @override
  bool operator ==(Object other) =>
      other is Wrapper && function == other.function;

  @override
  int get hashCode => function.hashCode;
}

void main() {
  final map = <Wrapper, int>{};
  final ref = Wrapper(main);
  map[ref] = 42;
  Expect.equals(42, map[ref]);

  testStaticEquality();
  testDynamicEquality();
}

void fn<T>(T t) => null;

/// Ensure `==` calls on function values that are statically typed as `Function`
///  or `Function?` work as expected.
void testStaticEquality() {
  Function staticFunction = fn;
  Expect.isTrue(staticFunction == fn);
  Expect.isFalse(staticFunction == main);

  Function? staticFunction2 = null;
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
