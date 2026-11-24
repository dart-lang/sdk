// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "shadowed_prefix_scope_part1.dart";

import "src/lib_x.dart" as p1 show x2;
import "src/lib_x.dart" as p2 show x2;

void inPart2() {
  String v;
  v = p2.x1; // Inherited
  v = p2.x2; // Imported
  v = p1.x2; // Imported
  v = p1.x1; // Not inherited, link p1 prefix lost in parent file.
  //     ^
  // [analyzer] error.undefined_identifier
  // [cfe] Undefined name 'x1'.
}
