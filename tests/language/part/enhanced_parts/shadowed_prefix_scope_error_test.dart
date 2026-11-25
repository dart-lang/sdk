// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=enhanced-parts

import "src/lib_x.dart" as p1 show x1;
import "src/lib_x.dart" as p2 show x1;

part "shadowed_prefix_scope_part1.dart";

void main() {
  inPart2();
}
