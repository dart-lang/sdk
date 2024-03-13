// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test tries to verify that catch entry moves correctly handle
// unboxed parameters and don't try to store values in locations
// where they will be missed by GC.

import 'dart:_internal' show VMInternalsForTesting;
import 'package:expect/expect.dart';

final values = <double>[];

@pragma('vm:never-inline')
void addValue(double v, {bool t = false}) {
  values.add(v);
  if (t) throw 'throw';
}

@pragma('vm:never-inline')
void tryCatch(double v) {
  try {
    addValue(v);
    // Modify v which would create a catch entry move for it.
    // Note: this should not be a constant value, because constant
    // value will survive GC.
    v *= 2;
    addValue(v, t: true);
  } catch (e) {
    VMInternalsForTesting.collectAllGarbage();
    addValue(v);
  }
}

void main() {
  tryCatch(1.0);
  tryCatch(2.0);
  Expect.listEquals([1.0, 2.0, 2.0, 2.0, 4.0, 4.0], values);
}
