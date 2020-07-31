// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that exports are handled for libraries loaded prior to the entry point
// library.
//
// This test uses the fact that dart2js loads dart:core before the
// reexport_core_helper and reexport_core_test libraries and the exports of
// dart:core is therefore computed before the exports of reexport_core_helper.

library reexport_core_test;

import "package:expect/expect.dart";
import 'reexport_core_helper.dart' as core;

void main() {
  var o = new Object();
  Expect.isTrue(o is core.Object);
}
