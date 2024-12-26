// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/f34a2ed99fc1b34cedbd974a5801f8d922121126/runtime/vm/isolate_reload_test.cc#L632

helper() {
  return max(3, 4);
}

Future<void> main() async {
  Expect.equals(4, helper());
  await hotReload(expectRejection: true);
  await hotReload();
  Expect.equals(42, helper());
}
/** DIFF **/
/*
@@ -2,7 +2,6 @@
 // for details. All rights reserved. Use of this source code is governed by a
 // BSD-style license that can be found in the LICENSE file.
 
-import 'dart:math';
 import 'package:expect/expect.dart';
 import 'package:reload_test/reload_test_utils.dart';
 
*/
