// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/be2aabd91c67f7f331c49cb74e18fe5e469f04db/runtime/vm/isolate_reload_test.cc#L2085

enum Fruit { Apple, Cantaloupe, Banana }

void helper() {
  Expect.equals(1, Fruit.Cantaloupe.index);
  Expect.equals('Fruit.Cantaloupe', Fruit.Cantaloupe.toString());
}

Future<void> main() async {
  Expect.equals(0, Fruit.Apple.index);
  Expect.equals('Fruit.Apple', Fruit.Apple.toString());
  Expect.equals(1, Fruit.Banana.index);
  Expect.equals('Fruit.Banana', Fruit.Banana.toString());
  await hotReload();

  Expect.equals(0, Fruit.Apple.index);
  Expect.equals('Fruit.Apple', Fruit.Apple.toString());
  Expect.equals(2, Fruit.Banana.index);
  Expect.equals('Fruit.Banana', Fruit.Banana.toString());
  helper();
}

/** DIFF **/
/*
@@ -8,9 +8,12 @@
 // Adapted from:
 // https://github.com/dart-lang/sdk/blob/be2aabd91c67f7f331c49cb74e18fe5e469f04db/runtime/vm/isolate_reload_test.cc#L2085
 
-enum Fruit { Apple, Banana }
+enum Fruit { Apple, Cantaloupe, Banana }
 
-void helper() {}
+void helper() {
+  Expect.equals(1, Fruit.Cantaloupe.index);
+  Expect.equals('Fruit.Cantaloupe', Fruit.Cantaloupe.toString());
+}
 
 Future<void> main() async {
   Expect.equals(0, Fruit.Apple.index);
*/
