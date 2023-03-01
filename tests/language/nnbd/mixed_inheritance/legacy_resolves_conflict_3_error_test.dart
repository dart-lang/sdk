// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-weak

// Verify that member signatures are computed correctly for null-safe
// classes having both a legacy and a null-safe superinterface, and with some
// classes also overriding declarations in the class itself. The expected
// member signatures are indicated in comments on each class in the library
// 'legacy_resolves_conflict_3_lib2.dart'. This test uses lack of assignability
// to ascertain that a selection of classes that are expected to have a
// null-safe member signature for `m` do not have a legacy member signature.

// The point is that 'legacy_resolves_conflict_3_test.dart' would succeed even
// in the case where, say, `DwB0().a` has type `List<int* Function(int*)>`,
// and similarly for other receiver types, but this test would then fail
// to have the corresponding compile-time errors.

import 'legacy_resolves_conflict_3_legacy_lib.dart';
import 'legacy_resolves_conflict_3_lib.dart';
import 'legacy_resolves_conflict_3_lib2.dart';

// Naming conventions: Please consult 'legacy_resolves_conflict_3_lib2.dart'.

class DiBqO0 implements C0, Bq {
  List<int Function(int)> get a => [];
//^
// [analyzer] unspecified
// [cfe] unspecified

  set a(List<int Function(int)> _) {}
//^
// [analyzer] unspecified
// [cfe] unspecified

  int Function(int) m(int Function(int) x) => x;
//^
// [analyzer] unspecified
// [cfe] unspecified
}

class DiBOq0 implements C0, B {
  List<int? Function(int?)> get a => [];
//^
// [analyzer] unspecified
// [cfe] unspecified

  set a(List<int? Function(int?)> _) {}
//^
// [analyzer] unspecified
// [cfe] unspecified

  int? Function(int?) m(int? Function(int?) x) => x;
//^
// [analyzer] unspecified
// [cfe] unspecified
}

class DiBqO1 implements C1, Bq {
  List<int Function(int)> get a => [];
//^
// [analyzer] unspecified
// [cfe] unspecified

  set a(List<int Function(int)> _) {}
//^
// [analyzer] unspecified
// [cfe] unspecified

  int Function(int) m(int Function(int) x) => x;
//^
// [analyzer] unspecified
// [cfe] unspecified
}

class DiBOq1 implements C1, B {
  List<int? Function(int?)> get a => [];
//^
// [analyzer] unspecified
// [cfe] unspecified

  set a(List<int? Function(int?)> _) {}
//^
// [analyzer] unspecified
// [cfe] unspecified

  int? Function(int?) m(int? Function(int?) x) => x;
//^
// [analyzer] unspecified
// [cfe] unspecified
}

class DiBqO2 implements C2, Bq {
  List<int Function(int)> get a => [];
//^
// [analyzer] unspecified
// [cfe] unspecified

  set a(List<int Function(int)> _) {}
//^
// [analyzer] unspecified
// [cfe] unspecified

  int Function(int) m(int Function(int) x) => x;
//^
// [analyzer] unspecified
// [cfe] unspecified
}

class DiBOq2 implements C2, B {
  List<int? Function(int?)> get a => [];
//^
// [analyzer] unspecified
// [cfe] unspecified

  set a(List<int? Function(int?)> _) {}
//^
// [analyzer] unspecified
// [cfe] unspecified

  int? Function(int?) m(int? Function(int?) x) => x;
//^
// [analyzer] unspecified
// [cfe] unspecified
}

class DiBqO3 implements C3, Bq {
  List<int Function(int)> get a => [];
//^
// [analyzer] unspecified
// [cfe] unspecified

  set a(List<int Function(int)> _) {}
//^
// [analyzer] unspecified
// [cfe] unspecified

  int Function(int) m(int Function(int) x) => x;
//^
// [analyzer] unspecified
// [cfe] unspecified
}

class DiBOq3 implements C3, B {
  List<int? Function(int?)> get a => [];
//^
// [analyzer] unspecified
// [cfe] unspecified

  set a(List<int? Function(int?)> _) {}
//^
// [analyzer] unspecified
// [cfe] unspecified

  int? Function(int?) m(int? Function(int?) x) => x;
//^
// [analyzer] unspecified
// [cfe] unspecified
}

class DiBqO4 implements C4, Bq {
  List<int Function(int)> get a => [];
//^
// [analyzer] unspecified
// [cfe] unspecified

  set a(List<int Function(int)> _) {}
//^
// [analyzer] unspecified
// [cfe] unspecified

  int Function(int) m(int Function(int) x) => x;
//^
// [analyzer] unspecified
// [cfe] unspecified
}

class DiBOq4 implements C4, B {
  List<int? Function(int?)> get a => [];
//^
// [analyzer] unspecified
// [cfe] unspecified

  set a(List<int? Function(int?)> _) {}
//^
// [analyzer] unspecified
// [cfe] unspecified

  int? Function(int?) m(int? Function(int?) x) => x;
//^
// [analyzer] unspecified
// [cfe] unspecified
}

class DiBqO5 implements C5, Bq {
  List<int Function(int)> get a => [];
//^
// [analyzer] unspecified
// [cfe] unspecified

  set a(List<int Function(int)> _) {}
//^
// [analyzer] unspecified
// [cfe] unspecified

  int Function(int) m(int Function(int) x) => x;
//^
// [analyzer] unspecified
// [cfe] unspecified
}

class DiBOq5 implements C5, B {
  List<int? Function(int?)> get a => [];
//^
// [analyzer] unspecified
// [cfe] unspecified

  set a(List<int? Function(int?)> _) {}
//^
// [analyzer] unspecified
// [cfe] unspecified

  int? Function(int?) m(int? Function(int?) x) => x;
//^
// [analyzer] unspecified
// [cfe] unspecified
}

void main() {
  // Verify that some classes have a signature which is not as in `Bq`.
  List<List<int? Function(int?)>> xsBq = [
    DwB0().a,
//  ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBO0().a,
//  ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DwB1().a,
//  ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBO1().a,
//  ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DwB2().a,
//  ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBO2().a,
//  ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DwB3().a,
//  ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBO3().a,
//  ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DwB4().a,
//  ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBO4().a,
//  ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DwB5().a,
//  ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBO5().a,
//  ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified
  ];

  // Verify that some classes have a signature which is not as in `B`.
  List<List<int Function(int)>> xsB = [
    DwBq0().a,
//  ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBqOq0().a,
//  ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DwBq1().a,
//  ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBqOq1().a,
//  ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DwBq2().a,
//  ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBqOq2().a,
//  ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DwBq3().a,
//  ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBqOq3().a,
//  ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DwBq4().a,
//  ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBqOq4().a,
//  ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DwBq5().a,
//  ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBqOq5().a,
//  ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified
  ];
}
