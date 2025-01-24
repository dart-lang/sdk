// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/be2aabd91c67f7f331c49cb74e18fe5e469f04db/runtime/vm/isolate_reload_test.cc#L2339

enum Fruit {
  Apple('Apple', 'A'),
  Banana('Banana', 'B'),
  Cherry('Cherry', 'C');

  const Fruit(this.name, this.initial);
  final String name;
  final String initial;
}

var retained;

helper() {
  Expect.equals('A', retained.initial);
  Expect.equals('A', Fruit.Apple.initial);
  Expect.equals('C', Fruit.Cherry.initial);
}

Future<void> main() async {
  retained = Fruit.Apple;
  Expect.equals('Fruit.Apple', retained.toString());
  await hotReload();
  helper();
}

/** DIFF **/
/*
@@ -8,11 +8,23 @@
 // Adapted from:
 // https://github.com/dart-lang/sdk/blob/be2aabd91c67f7f331c49cb74e18fe5e469f04db/runtime/vm/isolate_reload_test.cc#L2339
 
-enum Fruit { Apple, Banana }
+enum Fruit {
+  Apple('Apple', 'A'),
+  Banana('Banana', 'B'),
+  Cherry('Cherry', 'C');
 
+  const Fruit(this.name, this.initial);
+  final String name;
+  final String initial;
+}
+
 var retained;
 
-helper() {}
+helper() {
+  Expect.equals('A', retained.initial);
+  Expect.equals('A', Fruit.Apple.initial);
+  Expect.equals('C', Fruit.Cherry.initial);
+}
 
 Future<void> main() async {
   retained = Fruit.Apple;
*/
