// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that field promotion is prevented if there is another instance getter
// of the same name in the library that's a non-final field or a concrete
// getter.

import 'package:expect/static_type_helper.dart';

part 'field_promotion_name_conflicts_part.dart';

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
  final int? _f11;
  final int? _f12;
  final int? _f13;
  final int? _f14;

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
        _f10 = i,
        _f11 = i,
        _f12 = i,
        _f13 = i,
        _f14 = i;
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

enum E {
  e1,
  e2;

  int? get _f14 => 0;
}

void testFinalField(C c) {
  if (c._f1 != null) {
    c._f1.expectStaticType<Exactly<int>>();
  }
}

void testNonFinalField(C c) {
  if (c._f2 != null) {
    c._f2.expectStaticType<Exactly<int?>>();
  }
}

void testAbstractGetter(C c) {
  if (c._f3 != null) {
    c._f3.expectStaticType<Exactly<int>>();
  }
}

void testConcreteGetter(C c) {
  if (c._f4 != null) {
    c._f4.expectStaticType<Exactly<int?>>();
  }
}

void testSetter(C c) {
  if (c._f5 != null) {
    c._f5.expectStaticType<Exactly<int>>();
  }
}

void testStaticField(C c) {
  if (c._f6 != null) {
    c._f6.expectStaticType<Exactly<int>>();
  }
}

void testStaticGetter(C c) {
  if (c._f7 != null) {
    c._f7.expectStaticType<Exactly<int>>();
  }
}

void testTopLevelField(C c) {
  if (c._f8 != null) {
    c._f8.expectStaticType<Exactly<int>>();
  }
}

void testTopLevelGetter(C c) {
  if (c._f9 != null) {
    c._f9.expectStaticType<Exactly<int>>();
  }
}

void testExtensionGetter(C c) {
  if (c._f10 != null) {
    c._f10.expectStaticType<Exactly<int>>();
  }
}

void testGetterInPart(C c) {
  if (c._f11 != null) {
    c._f11.expectStaticType<Exactly<int?>>();
  }
}

void testFieldInMixin(C c) {
  if (c._f12 != null) {
    c._f12.expectStaticType<Exactly<int?>>();
  }
}

void testGetterInMixin(C c) {
  if (c._f13 != null) {
    c._f13.expectStaticType<Exactly<int?>>();
  }
}

void testGetterInEnum(C c) {
  if (c._f14 != null) {
    c._f14.expectStaticType<Exactly<int?>>();
  }
}

main() {
  for (var c in [C(null), C(0)]) {
    testFinalField(c);
    testNonFinalField(c);
    testAbstractGetter(c);
    testConcreteGetter(c);
    testSetter(c);
    testStaticField(c);
    testStaticGetter(c);
    testTopLevelField(c);
    testTopLevelGetter(c);
    testExtensionGetter(c);
    testGetterInPart(c);
    testFieldInMixin(c);
    testGetterInMixin(c);
    testGetterInEnum(c);
  }
}
