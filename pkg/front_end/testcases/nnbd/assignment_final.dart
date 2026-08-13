// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  dynamic field1;
  dynamic field2;
}

method(x, y, z) {
  final initializedFinal = 5;
  late final initializedLateFinal = 5;

  final definitelyUnassignedFinal;
  late final int definitelyUnassignedLateFinal;

  final definitelyAssignedFinal;
  late final definitelyAssignedLateFinal;

  final int notDefinitelyAssignedFinal;
  late final int notDefinitelyAssignedLateFinal;

  if (x == 5) {
    notDefinitelyAssignedFinal = 5;
    notDefinitelyAssignedLateFinal = 15;
  }

  definitelyAssignedFinal = 10;
  definitelyAssignedLateFinal = 20;

  initializedFinal = x; // Error
  initializedLateFinal = x; // Error

  definitelyUnassignedFinal = x; // Ok
  definitelyUnassignedLateFinal = y; // Ok

  definitelyAssignedFinal = y; // Error
  definitelyAssignedLateFinal = z; // Error

  notDefinitelyAssignedFinal = z; // Error
  notDefinitelyAssignedLateFinal = z; // Ok
}
