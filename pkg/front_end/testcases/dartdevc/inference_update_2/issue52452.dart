// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that field promotion is prevented if there is a synthetic instance
// getter of the same name in the library that's a noSuchMethod forwarder.

// SharedOptions=--enable-experiment=inference-update-2

class C {
  final int? _f2;
  final int? _f3;
  final int? _f4;

  C(int? i)
      : _f2 = i,
        _f3 = i,
        _f4 = i;
}

class A {
  A(int? i);
}

mixin M3 {}

abstract class D extends A with M3 {
  final int? _f4;

  D(int? i)
      : _f4 = i,
        super(i);
}

mixin M1 {
  late int? _f2;
  late final int? _f3;
  late final int? _f4 = 0;
}

class B {
  B(int? i);
}

class E extends B with M1 implements D {
  E(super.i);
  // Inherits _f4 from M1, so there is no noSuchMethod forwarder

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void acceptsInt(int x) {}

void testConflictWithNoSuchMethodForwarderIfImplementedInMixin(C c) {
  if (c._f2 != null) {
    var x = c._f2;
    // `x` has type `int?` so this is ok
    x = null;
  }
}

void testNoConflictWithNoSuchMethodForwarderIfImplementedInMixin1(C c) {
  if (c._f3 != null) {
    var x = c._f3;
    // `x` has type `int` so this is ok
    acceptsInt(x);
  }
}

void testNoConflictWithNoSuchMethodForwarderIfImplementedInMixin2(C c) {
  if (c._f4 != null) {
    var x = c._f4;
    // `x` has type `int` so this is ok
    acceptsInt(x);
  }
}

main() {
  for (var c in [C(null), C(0)]) {
    testConflictWithNoSuchMethodForwarderIfImplementedInMixin(c);
    testNoConflictWithNoSuchMethodForwarderIfImplementedInMixin1(c);
    testNoConflictWithNoSuchMethodForwarderIfImplementedInMixin2(c);
  }
}
