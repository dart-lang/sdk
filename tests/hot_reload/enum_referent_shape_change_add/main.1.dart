// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/be2aabd91c67f7f331c49cb74e18fe5e469f04db/runtime/vm/isolate_reload_test.cc#L2402

class Box {
  final x;
  final y;
  final z;
  const Box(this.x, this.y, this.z);
}

enum Fruit {
  Apple('Apple', const Box('A', 0, 0)),
  Banana('Banana', const Box('B', 0, 0)),
  Cherry('Cherry', const Box('C', 0, 0)),
  Durian('Durian', const Box('D', 0, 0)),
  Elderberry('Elderberry', const Box('E', 0, 0)),
  Fig('Fig', const Box('F', 0, 0)),
  Grape('Grape', const Box('G', 0, 0)),
  Huckleberry('Huckleberry', const Box('H', 0, 0)),
  Jackfruit('Jackfruit', const Box('J', 0, 0)),
  Lemon('Lemon', const Box('L', 0, 0));

  const Fruit(this.name, this.initial);
  final String name;
  final Box initial;
}

var retained;

Future<void> main() async {
  retained = Fruit.Apple;
  Expect.equals('Fruit.Apple', retained.toString());
  await hotReload();
  Expect.equals('Fruit.Apple', retained.toString());
}

/** DIFF **/
/*
@@ -10,19 +10,22 @@
 
 class Box {
   final x;
-  const Box(this.x);
+  final y;
+  final z;
+  const Box(this.x, this.y, this.z);
 }
 
 enum Fruit {
-  Apple('Apple', const Box('A')),
-  Banana('Banana', const Box('B')),
-  Cherry('Cherry', const Box('C')),
-  Durian('Durian', const Box('D')),
-  Elderberry('Elderberry', const Box('E')),
-  Fig('Fig', const Box('F')),
-  Grape('Grape', const Box('G')),
-  Huckleberry('Huckleberry', const Box('H')),
-  Jackfruit('Jackfruit', const Box('J'));
+  Apple('Apple', const Box('A', 0, 0)),
+  Banana('Banana', const Box('B', 0, 0)),
+  Cherry('Cherry', const Box('C', 0, 0)),
+  Durian('Durian', const Box('D', 0, 0)),
+  Elderberry('Elderberry', const Box('E', 0, 0)),
+  Fig('Fig', const Box('F', 0, 0)),
+  Grape('Grape', const Box('G', 0, 0)),
+  Huckleberry('Huckleberry', const Box('H', 0, 0)),
+  Jackfruit('Jackfruit', const Box('J', 0, 0)),
+  Lemon('Lemon', const Box('L', 0, 0));
 
   const Fruit(this.name, this.initial);
   final String name;
@@ -37,3 +40,4 @@
   await hotReload();
   Expect.equals('Fruit.Apple', retained.toString());
 }
+
*/
