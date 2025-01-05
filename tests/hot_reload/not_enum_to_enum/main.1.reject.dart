// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/be2aabd91c67f7f331c49cb74e18fe5e469f04db/runtime/vm/isolate_reload_test.cc#L2145

enum Fruit { Apple }

Future<void> main() async {
  await hotReload(expectRejection: true);
}

/** DIFF **/
/*
@@ -8,10 +8,9 @@
 // Adapted from:
 // https://github.com/dart-lang/sdk/blob/be2aabd91c67f7f331c49cb74e18fe5e469f04db/runtime/vm/isolate_reload_test.cc#L2145
 
-class Fruit {
-  final int zero = 0;
-}
+enum Fruit { Apple }
 
 Future<void> main() async {
   await hotReload(expectRejection: true);
 }
+
*/
