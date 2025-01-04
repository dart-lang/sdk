// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/be2aabd91c67f7f331c49cb74e18fe5e469f04db/runtime/vm/isolate_reload_test.cc#L2050

enum Fruit { Banana, Apple }

var x;

Future<void> main() async {
  x = Fruit.Banana;
  await hotReload();
  Expect.equals(Fruit.Banana, x);
  Expect.identical(Fruit.Banana, x);
}

/** DIFF **/
/*
@@ -8,7 +8,7 @@
 // Adapted from:
 // https://github.com/dart-lang/sdk/blob/be2aabd91c67f7f331c49cb74e18fe5e469f04db/runtime/vm/isolate_reload_test.cc#L2050
 
-enum Fruit { Apple, Banana }
+enum Fruit { Banana, Apple }
 
 var x;
 
@@ -18,3 +18,4 @@
   Expect.equals(Fruit.Banana, x);
   Expect.identical(Fruit.Banana, x);
 }
+
*/
