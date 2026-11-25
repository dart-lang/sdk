// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "../enhanced_parts_test.dart";

import "../src/lib_x.dart" show x4, x5;
import "../src/lib_xy.dart" show x2;
import "../src/lib_x.dart" as p1 show x4, x5;
import "../src/lib_xy.dart" as p1 show x2;
import "../src/lib_p.dart" show p2;
import "../src/lib_x.dart" as p3 show x1, x2, x3;

import "shadowed_names.dart";

export "../src/lib_e.dart" show e2;

part 'part_aa.dart';
part 'part_ab.dart';

(List<String> Function(), List<String>) partA() {
  Expect.isTrue(isShadowedNamesImported);

  // All top-level declarations visible in all files.
  Expect.equals("main", self.mainVar);
  Expect.equals("partA", self.partAVar);
  Expect.equals("partB", self.partBVar);
  Expect.equals("partAA", self.partAAVar);
  Expect.equals("partAB", self.partABVar);
  Expect.equals("partAAA", self.partAAAVar);

  // Inherited imports are visible unless shadowed.
  Expect.equals("x1", p0.x1);

  Expect.equals('x1', x1); // Inherited.
  Expect.equals('y2', x2); // Shadowed.
  Expect.equals('x3', x3); // Inherited.
  Expect.equals('x4', x4); // Imported.
  Expect.equals('x5', x5); // Imported.

  Expect.equals('x1', p1.x1); // Inherited.
  Expect.equals('y2', p1.x2); // Shadowed.
  Expect.equals('x3', p1.x3); // Inherited.
  Expect.equals('x4', p1.x4); // Imported.
  Expect.equals('x5', p1.x5); // Imported.

  Expect.equals('p2', p2); // Shadowed prefix.

  Expect.equals('x1', p3.x1); // Imported.
  Expect.equals('x2', p3.x2); // Imported.
  Expect.equals('x3', p3.x3); // Imported.

  // Check that closure closes over correct scope.
  return (() => [x1, x2, x3, x4, x5], [x1, x2, x3, x4, x5]);
}

String get partAVar => "partA";
