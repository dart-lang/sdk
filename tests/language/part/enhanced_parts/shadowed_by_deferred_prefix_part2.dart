// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "shadowed_by_deferred_prefix_part1.dart";

import "src/lib_x.dart" as p1 show x3;

void inPart2() {
  String v;
  v = p1.x3; // Imported
  v = p1.x1; // Not inherited, link p1 prefix lost in parent file.
  //     ^
  // [analyzer] error.undefined_identifier
  // [cfe] Undefined name 'x1'.
  v = p1.x2; // Not inherited from deferred import.
  //     ^
  // [analyzer] error.undefined_identifier
  // [cfe] Undefined name 'x2'.
}
