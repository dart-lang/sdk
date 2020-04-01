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

import 'legacy_resolves_conflict_3_lib2.dart';

void main() {
  // Verify that some classes have a signature which is not as in `Bq`.
  List<List<int? Function(int?)>> xsBq = [
    DwB0().a,
//  ^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBO0().a,
//  ^^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBqO0().a,
//  ^^^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DwB1().a,
//  ^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBO1().a,
//  ^^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBqO1().a,
//  ^^^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DwB2().a,
//  ^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBO2().a,
//  ^^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBqO2().a,
//  ^^^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DwB3().a,
//  ^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBO3().a,
//  ^^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBqO3().a,
//  ^^^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DwB4().a,
//  ^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBO4().a,
//  ^^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBqO4().a,
//  ^^^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DwB5().a,
//  ^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBO5().a,
//  ^^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBqO5().a,
//  ^^^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified
  ];

  // Verify that some classes have a signature which is not as in `B`.
  List<List<int Function(int)>> xsB = [
    DwBq0().a,
//  ^^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBOq0().a,
//  ^^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBqOq0().a,
//  ^^^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DwBq1().a,
//  ^^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBOq1().a,
//  ^^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBqOq1().a,
//  ^^^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DwBq2().a,
//  ^^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBOq2().a,
//  ^^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBqOq2().a,
//  ^^^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DwBq3().a,
//  ^^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBOq3().a,
//  ^^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBqOq3().a,
//  ^^^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DwBq4().a,
//  ^^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBOq4().a,
//  ^^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBqOq4().a,
//  ^^^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DwBq5().a,
//  ^^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBOq5().a,
//  ^^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified

    DiBqOq5().a,
//  ^^^^^^^^^^
// [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
// [cfe] unspecified
  ];
}
