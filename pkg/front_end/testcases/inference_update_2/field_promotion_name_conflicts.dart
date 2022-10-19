// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that field promotion is prevented if there is another instance getter
// of the same name in the library that's a non-final field or a concrete
// getter.

part 'field_promotion_name_conflicts_part.dart';

abstract class C {
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
  final int? _f11;
  final int? _f12;
  final int? _f13;

  C(int? i) : _f1 = i, _f2 = i, _f3 = i, _f4 = i, _f5 = i, _f6 = i, _f7 = i, _f8 = i, _f9 = i, _f10 = i, _f11 = i, _f12 = i, _f13 = i;
}

abstract class D {
  final int? _f1;
  int? _f2;
  int? get _f3;
  int? get _f4 => 0;
  set _f5(int? i) {}
  static int? _f6;
  static int? get _f7 => 0;

  D(int? i) : _f1 = i;
}

int? _f8;
int? get _f9 => 0;

extension on String {
  int? get _f10 => 0;
}

mixin M {
  int? _f12;
  int? get _f13 => 0;
}

void acceptsInt(int x) {}

void testFinalField(C c) {
  if (c._f1 != null) {
    var x = c._f1;
    // `x` has type `int` so this is ok
    acceptsInt(x);
  }
}

void testNonFinalField(C c) {
  if (c._f2 != null) {
    var x = c._f2;
    // `x` has type `int?` so this is ok
    x = null;
  }
}

void testAbstractGetter(C c) {
  if (c._f3 != null) {
    var x = c._f3;
    // `x` has type `int` so this is ok
    acceptsInt(x);
  }
}

void testConcreteGetter(C c) {
  if (c._f4 != null) {
    var x = c._f4;
    // `x` has type `int?` so this is ok
    x = null;
  }
}

void testSetter(C c) {
  if (c._f5 != null) {
    var x = c._f5;
    // `x` has type `int` so this is ok
    acceptsInt(x);
  }
}

void testStaticField(C c) {
  if (c._f6 != null) {
    var x = c._f6;
    // `x` has type `int` so this is ok
    acceptsInt(x);
  }
}

void testStaticGetter(C c) {
  if (c._f7 != null) {
    var x = c._f7;
    // `x` has type `int` so this is ok
    acceptsInt(x);
  }
}

void testTopLevelField(C c) {
  if (c._f8 != null) {
    var x = c._f8;
    // `x` has type `int` so this is ok
    acceptsInt(x);
  }
}

void testTopLevelGetter(C c) {
  if (c._f9 != null) {
    var x = c._f9;
    // `x` has type `int` so this is ok
    acceptsInt(x);
  }
}

void testExtensionGetter(C c) {
  if (c._f10 != null) {
    var x = c._f10;
    // `x` has type `int` so this is ok
    acceptsInt(x);
  }
}

void testGetterInPart(C c) {
  if (c._f11 != null) {
    var x = c._f11;
    // `x` has type `int?` so this is ok
    x = null;
  }
}

void testFieldInMixin(C c) {
  if (c._f12 != null) {
    var x = c._f12;
    // `x` has type `int?` so this is ok
    x = null;
  }
}

void testGetterInMixin(C c) {
  if (c._f13 != null) {
    var x = c._f13;
    // `x` has type `int?` so this is ok
    x = null;
  }
}

main() {}
