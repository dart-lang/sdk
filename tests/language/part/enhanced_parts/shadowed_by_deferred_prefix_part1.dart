// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "shadowed_by_deferred_prefix_error_test.dart";

import "src/lib_x.dart" deferred as p1 show x2;
part "shadowed_by_deferred_prefix_part2.dart";

void inPart1() async {
  await p1.loadLibrary();
  String v;
  v = p1.x2;
  v = p1.x1;
  //     ^
  // [analyzer] unspecified
  // [cfe] Undefined name 'x1'.
}
