// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "part_a.dart";

import "../src/lib_x.dart" show x6;
import "../src/lib_xy.dart" show x4;
import "../src/lib_x.dart" as p1 show x6;
import "../src/lib_xy.dart" as p1 show x4;
import "../src/lib_x.dart" as p2 show x4;

// ignore: unused_import
import "shadowed_names.dart";

export "../src/lib_e.dart" show e5;

(List<String> Function(), List<String>) partAB() {
  // Top-level declarations are in all scopes.
  Expect.equals("main", mainVar);
  Expect.equals("partA", partAVar);
  Expect.equals("partB", partBVar);
  Expect.equals("partAA", partAAVar);
  Expect.equals("partAB", partABVar);
  Expect.equals("partAAA", partAAAVar);

  // Inherited imports are visible unless shadowed.
  Expect.equals("x1", p0.x1);

  Expect.equals('x1', x1); // Inherited.
  Expect.equals('y2', x2); // Inherited shadowed.
  Expect.equals('x3', x3); // Inherited.
  Expect.equals('y4', x4); // Shadowed.
  Expect.equals('x5', x5); // Inherited.
  Expect.equals('x6', x6); // Imported.

  Expect.equals('x1', p1.x1); // Inherited.
  Expect.equals('y2', p1.x2); // Inherited shadowed.
  Expect.equals('x3', p1.x3); // Inherited.
  Expect.equals('y4', p1.x4); // Shadowed.
  Expect.equals('x5', p1.x5); // Inherited.
  Expect.equals('x6', p1.x6); // Imported.

  Expect.equals('x4', p2.x4); // New prefix.

  // Check that closure closes over correct scope.
  return (() => [x1, x2, x3, x6], [x1, x2, x3, x6]);
}

String get partABVar => "partAB";
