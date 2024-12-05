// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/63622f03eeaf72983b2f4957fa84da8062693f00/runtime/vm/isolate_reload_test.cc#L4968

class Foo {
  int x = 4;
  int y = 6;
}

late Foo value;

helper() {
  return value.y;
}

Future<void> main() async {
  Expect.equals(4, helper());
  Expect.equals(0, hotReloadGeneration);

  await hotReload();

  // Add the field y with an initialize, but do no read it
  Expect.equals(0, helper());
  Expect.equals(1, hotReloadGeneration);

  await hotReload();

  // Change y's initializer and check this new initializer is used.
  Expect.equals(6, helper());
  Expect.equals(2, hotReloadGeneration);
}
/** DIFF **/
/*
@@ -10,13 +10,13 @@
 
 class Foo {
   int x = 4;
-  int y = 5;
+  int y = 6;
 }
 
 late Foo value;
 
 helper() {
-  return 0;
+  return value.y;
 }
 
 Future<void> main() async {
*/
