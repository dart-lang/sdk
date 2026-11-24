// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "part_aa.dart";

import "../src/lib_x.dart" show x7;
import "../src/lib_xy.dart" show x6;
import "../src/lib_x.dart" as p1 show x7;
import "../src/lib_xy.dart" as p1 show x6;
import "../src/lib_x.dart" deferred as p2 show x5;

import "shadowed_names.dart";

export "../src/lib_e.dart" show e6;

(List<String> Function(), List<String>) partAAA() {
  Expect.isTrue(isShadowedNamesImported);

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
  Expect.equals('y4', x4); // Inherited shadowed.
  Expect.equals('x5', x5); // Inherited.
  Expect.equals('y6', x6); // Shadowed.
  Expect.equals('x7', x7); // Imported.

  Expect.equals('x1', p1.x1); // Inherited.
  Expect.equals('y2', p1.x2); // Inherited shadowed.
  Expect.equals('x3', p1.x3); // Inherited.
  Expect.equals('y4', p1.x4); // Inherited shadowed.
  Expect.equals('x5', p1.x5); // Inherited.
  Expect.equals('y6', p1.x6); // Shadowed.
  Expect.equals('x7', p1.x7); // Imported.

  asyncStart();
  p2.loadLibrary().then((_) {
    Expect.equals('x5', p2.x5); // New prefix.
    asyncEnd();
  });

  // Check that closure closes over correct scope.
  return (() => [x1, x2, x3, x4, x5, x6, x7], [x1, x2, x3, x4, x5, x6, x7]);
}

String get partAAAVar => "partAAA";
