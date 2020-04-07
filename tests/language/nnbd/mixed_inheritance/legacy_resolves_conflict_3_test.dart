// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-weak

// Verify that member signatures are computed correctly for null-safe
// classes having both a legacy and a null-safe superinterface, and with some
// classes also overriding declarations in the class itself. The expected
// member signatures are indicated in comments on each class in the library
// 'legacy_resolves_conflict_3_lib2.dart'. This test uses assignability to
// confirm that the return type of the getter `a` is assignable to the
// expected type; 'legacy_resolves_conflict_3_error_test.dart' complements
// this by ascertaining that said return type is not legacy.

import 'package:expect/expect.dart';
import 'legacy_resolves_conflict_3_lib.dart';
import 'legacy_resolves_conflict_3_lib2.dart';

void main() {
  // Ensure that no class is eliminated by tree-shaking.
  Expect.isNotNull([
    DiB0, DiBq0, DwB0, DwBq0, DiBO0, DiBqOq0, //
    DiB1, DiBq1, DwB1, DwBq1, DiBO1, DiBqOq1, //
    DiB2, DiBq2, DwB2, DwBq2, DiBO2, DiBqOq2, //
    DiB3, DiBq3, DwB3, DwBq3, DiBO3, DiBqOq3, //
    DiB4, DiBq4, DwB4, DwBq4, DiBO4, DiBqOq4, //
    DiB5, DiBq5, DwB5, DwBq5, DiBO5, DiBqOq5, //
  ]);

  // Verify that some classes have a signature as in `B`.
  List<List<int Function(int)>> xsB = [
    DiB0().a, DwB0().a, DiBO0().a, DiB1().a, DwB1().a, DiBO1().a, //
    /*DiB2,*/ DwB2().a, DiBO2().a, DiB3().a, DwB3().a, DiBO3().a, //
    DiB4().a, DwB4().a, DiBO4().a, /*DiB5,*/ DwB5().a, DiBO5().a, //
  ];

  // Verify that some classes have a signature as in `Bq`.
  List<List<int? Function(int?)>> xsBq = [
    DiBq0().a, DwBq0().a, DiBqOq0().a, DiBq1().a, DwBq1().a, DiBqOq1().a, //
    /*DiBq2,*/ DwBq2().a, DiBqOq2().a, DiBq3().a, DwBq3().a, DiBqOq3().a, //
    DiBq4().a, DwBq4().a, DiBqOq4().a, /*DiBq5,*/ DwBq5().a, DiBqOq5().a, //
  ];

  void testAbstractClasses(DiB2 diB2, DiBq2 diBq2, DiB5 diB5, DiBq5 diBq5) {
    List<List<int Function(int)>> xsB = [diB2.a, diB5.a];
    List<List<int? Function(int?)>> xsBq = [diBq2.a, diBq5.a];
    print("$xsB, $xsBq");
  }
}
