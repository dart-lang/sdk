// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/be2aabd91c67f7f331c49cb74e18fe5e469f04db/runtime/vm/isolate_reload_test.cc#L2170

enum Fruit { Apple, Banana }

var x;

Future<void> main() async {
  Expect.equals('Fruit.Cantaloupe', x.toString());
  Expect.type<int>(x.hashCode);
  Expect.equals(2, x.index);
  await hotReload();

  Expect.equals('Fruit.Deleted enum value from Fruit', x.toString());
  Expect.type<int>(x.hashCode);
  Expect.equals(-1, x.index);
}

/** DIFF **/
/*
@@ -8,12 +8,11 @@
 // Adapted from:
 // https://github.com/dart-lang/sdk/blob/be2aabd91c67f7f331c49cb74e18fe5e469f04db/runtime/vm/isolate_reload_test.cc#L2170
 
-enum Fruit { Apple, Banana, Cantaloupe }
+enum Fruit { Apple, Banana }
 
 var x;
 
 Future<void> main() async {
-  x = Fruit.Cantaloupe;
   Expect.equals('Fruit.Cantaloupe', x.toString());
   Expect.type<int>(x.hashCode);
   Expect.equals(2, x.index);
*/
