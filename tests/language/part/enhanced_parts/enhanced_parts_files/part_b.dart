// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "../enhanced_parts_test.dart";

import "../src/lib_x.dart" show x8;
import "../src/lib_xy.dart" show x3;
import "../src/lib_x.dart" as p1 show x8;
import "../src/lib_xy.dart" as p1 show x3;
import "../src/lib_x.dart" as p3 show x4, x5;

import "shadowed_names.dart";

export "../src/lib_e.dart" show e3;

(List<String> Function(), List<String>) partB() {
  Expect.isTrue(isShadowedNamesImported);

  // All top-level declarations visible in all files.
  Expect.equals("main", mainVar);
  Expect.equals("partA", partAVar);
  Expect.equals("partB", partBVar);
  Expect.equals("partAA", partAAVar);
  Expect.equals("partAB", partABVar);
  Expect.equals("partAAA", partAAAVar);

  // Inherited imports are visible unless shadowed.
  Expect.equals("x1", p0.x1);

  Expect.equals('x1', x1); // Inherited.
  Expect.equals('x2', x2); // Shadowed.
  Expect.equals('y3', x3); // Inherited.
  Expect.equals('x8', x8); // Imported.

  Expect.equals('x1', p1.x1); // Inherited.
  Expect.equals('x2', p1.x2); // Inherited.
  Expect.equals('y3', p1.x3); // Shadowed.
  Expect.equals('x8', p1.x8); // Imported.

  Expect.equals('x4', p3.x4); // Imported.
  Expect.equals('x5', p3.x5); // Imported.

  // Check that closure closes over correct scope.
  return (() => [x1, x2, x3, p3.x4, p3.x5, x8], [x1, x2, x3, p3.x4, p3.x5, x8]);
}

String get partBVar => "partB";
