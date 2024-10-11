// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that field promotion is prevented if there is a synthetic instance
// getter of the same name in the library that's a noSuchMethod forwarder.

import 'package:expect/static_type_helper.dart';

import 'field_promotion_and_no_such_method_lib.dart' as otherLib;

class C {
  final int? _f1;
  final int? _f2;
  final int? _f3;
  final int? _f4;
  final int? _f5;
  final int? _f6;
  final int? _f7;
  final int? _f8;
  final int? _f9;
  final int? _f10;

  C(int? i)
      : _f1 = i,
        _f2 = i,
        _f3 = i,
        _f4 = i,
        _f5 = i,
        _f6 = i,
        _f7 = i,
        _f8 = i,
        _f9 = i,
        _f10 = i;
}

class A {
  final int? _f7;

  A(int? i) : _f7 = i;
}

mixin M3 {
  late final int? _f8 = 0;
}

abstract class D extends A with M3 {
  final int? _f1;
  final int? _f4;
  final int? _f5;
  int? get _f10;

  D(int? i)
      : _f1 = i,
        _f4 = i,
        _f5 = i,
        super(i);
}

mixin M1 {
  late final int? _f4 = 0;
}

class B {
  final int? _f5;

  B(int? i) : _f5 = i;
}

class E extends B with M1 implements D {
  E(super.i);
  // Implicitly implements _f1 as a getter that forwards to noSuchMethod
  // Inherits _f4 from M1, so there is no noSuchMethod forwarder
  // Inherits _f5 from B, so there is no noSuchMethod forwarder
  // Implicitly implements _f7 from A as a getter that forwards to noSuchMethod
  // Implicitly implements _f8 from M3 as a getter that forwards to noSuchMethod
  // Implicitly implements _f10 as a getter that forwards to noSuchMethod

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class F implements otherLib.C {
  // Implicitly implements _f2 as a getter that throws; but the name _f2 comes
  // from the other library so it doesn't conflict with the _f2 in this library.

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

abstract class G {
  final int? _f3;

  G(int? i) : _f3 = i;
}

mixin M2 {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Implicitly implements _f3 as a getter that forwards to M2.noSuchMethod
class H = Object with M2 implements G;

class I {
  final int? _f6;

  I(int? i) : _f6 = i;
}

enum J implements I {
  j1,
  j2;
  // Implicitly implements _f6 as a getter that forwards to noSuchMethod

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class K {
  final int? _f9;

  K(int? i) : _f9 = i;
}

mixin M4 implements K {
  // Mixins are implicitly abstract, so this does not implement _f9 as a getter
  // that forwards to noSuchMethod

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void testConflictsWithNoSuchMethodForwarder(C c) {
  if (c._f1 != null) {
    c._f1.expectStaticType<Exactly<int?>>();
  }
}

void testNoConflictWithNoSuchMethodForwarderForDifferentLib(C c) {
  if (c._f2 != null) {
    c._f2.expectStaticType<Exactly<int>>();
  }
}

void testConflictsWithNoSuchMethodForwarderViaClassTypeAlias(C c) {
  if (c._f3 != null) {
    c._f3.expectStaticType<Exactly<int?>>();
  }
}

void testNoConflictWithNoSuchMethodForwarderIfImplementedInMixin(C c) {
  if (c._f4 != null) {
    c._f4.expectStaticType<Exactly<int>>();
  }
}

void testNoConflictWithNoSuchMethodForwarderIfImplementedInSuperclass(C c) {
  if (c._f5 != null) {
    c._f5.expectStaticType<Exactly<int>>();
  }
}

void testConflictsWithNoSuchMethodForwarderInEnum(C c) {
  if (c._f6 != null) {
    c._f6.expectStaticType<Exactly<int?>>();
  }
}

void testConflictsWithNoSuchMethodForwarderThroughInheritedInterface(C c) {
  if (c._f7 != null) {
    c._f7.expectStaticType<Exactly<int?>>();
  }
}

void testConflictsWithNoSuchMethodForwarderThroughMixedInInterface(C c) {
  if (c._f8 != null) {
    c._f8.expectStaticType<Exactly<int?>>();
  }
}

void testNoConflictWithNoSuchMethodForwarderInUnusedMixin(C c) {
  if (c._f9 != null) {
    c._f9.expectStaticType<Exactly<int>>();
  }
}

void testConflictsWithNoSuchMethodForwarderBasedOnAbstractGetter(C c) {
  if (c._f10 != null) {
    c._f10.expectStaticType<Exactly<int?>>();
  }
}

main() {
  for (var c in [C(null), C(0)]) {
    testConflictsWithNoSuchMethodForwarder(c);
    testNoConflictWithNoSuchMethodForwarderForDifferentLib(c);
    testConflictsWithNoSuchMethodForwarderViaClassTypeAlias(c);
    testNoConflictWithNoSuchMethodForwarderIfImplementedInMixin(c);
    testNoConflictWithNoSuchMethodForwarderIfImplementedInSuperclass(c);
    testConflictsWithNoSuchMethodForwarderInEnum(c);
    testConflictsWithNoSuchMethodForwarderThroughInheritedInterface(c);
    testConflictsWithNoSuchMethodForwarderThroughMixedInInterface(c);
    testNoConflictWithNoSuchMethodForwarderInUnusedMixin(c);
    testConflictsWithNoSuchMethodForwarderBasedOnAbstractGetter(c);
  }
}
