// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/63622f03eeaf72983b2f4957fa84da8062693f00/runtime/vm/isolate_reload_test.cc#L5021

int myInitialValue = 8 * 7;

class Foo {
  int x = 4;
  int y = myInitialValue++;
}

late Foo value;
late Foo value1;

helper() {
  return '$myInitialValue';
}

Future<void> main() async {
  Expect.equals('4', helper());
  Expect.equals(0, hotReloadGeneration);

  await hotReload();

  // Add the field y. Do not touch y.
  Expect.equals('56', helper());
  Expect.equals(1, hotReloadGeneration);

  await hotReload();

  // Field y's getter must be retained for initialization even
  // though it is no longer new.
  Expect.equals('56 56 57 58', helper());
  Expect.equals(2, hotReloadGeneration);
}
/** DIFF **/
/*
@@ -12,15 +12,14 @@
 
 class Foo {
   int x = 4;
+  int y = myInitialValue++;
 }
 
 late Foo value;
 late Foo value1;
 
 helper() {
-  value = Foo();
-  value1 = Foo();
-  return '${value.x}';
+  return '$myInitialValue';
 }
 
 Future<void> main() async {
*/
