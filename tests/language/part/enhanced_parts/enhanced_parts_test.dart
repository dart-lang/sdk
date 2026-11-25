// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=enhanced-parts

// Tests enhanced parts.
// Checks that parts can contain imports, exports and other parts.
// All part files are in the `enhanced_parts_files/` directory
// for files used only by this test, or `src/` directory for files shared
// with other tests.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

import "src/lib_x.dart" as p0 show x1;
import "src/lib_x.dart" show x1, x2, x3;
import "src/lib_x.dart" as p1 show x1, x2, x3;
import "src/lib_x.dart" as p2 show x1, x2, x3;

import "enhanced_parts_files/shadowed_names.dart";

import "enhanced_parts_test.dart" as self;

export "src/lib_e.dart" show e1;

part 'enhanced_parts_files/part_a.dart';
part 'enhanced_parts_files/part_b.dart';

String get mainVar => "main";

void main() {
  asyncStart(); // Async for deferred import.

  Expect.isTrue(isShadowedNamesImported);

  // Declarations in all parts are visible in all parts.
  Expect.equals("main", mainVar);
  Expect.equals("partA", partAVar);
  Expect.equals("partB", partBVar);
  Expect.equals("partAA", partAAVar);
  Expect.equals("partAB", partABVar);
  Expect.equals("partAAA", partAAAVar);

  // Public declarations in all parts are exported.
  Expect.equals("main", self.mainVar);
  Expect.equals("partA", self.partAVar);
  Expect.equals("partB", self.partBVar);
  Expect.equals("partAA", self.partAAVar);
  Expect.equals("partAB", self.partABVar);
  Expect.equals("partAAA", self.partAAAVar);

  // Exports from all files are exported.
  Expect.equals("e1", self.e1);
  Expect.equals("e2", self.e2);
  Expect.equals("e3", self.e3);
  Expect.equals("e4", self.e4);
  Expect.equals("e5", self.e5);
  Expect.equals("e6", self.e6);

  // Imports in library file are visible.
  Expect.equals("x1", x1);
  Expect.equals("x2", x2);
  Expect.equals("x3", x3);

  // Inherited imports are visible unless shadowed.
  Expect.equals("x1", p0.x1);

  Expect.equals("x1", p1.x1);
  Expect.equals("x2", p1.x2);
  Expect.equals("x3", p1.x3);

  Expect.equals("x1", p2.x1);
  Expect.equals("x2", p2.x2);
  Expect.equals("x3", p2.x3);

  // Each part tests its own scope. (Also checks that these are all in scope).
  // Returns a closure closing over imports in that file, and the values
  // of those imports in that file. Checks that the closure retains its binding
  // when run in a different file.
  List<String> Function() topLevels;
  List<String> expected;
  (topLevels, expected) = partA();
  Expect.listEquals(expected, topLevels());
  (topLevels, expected) = partB();
  Expect.listEquals(expected, topLevels());
  (topLevels, expected) = partAA();
  Expect.listEquals(expected, topLevels());
  (topLevels, expected) = partAB();
  Expect.listEquals(expected, topLevels());
  (topLevels, expected) = partAAA();
  Expect.listEquals(expected, topLevels());

  asyncEnd();
}
