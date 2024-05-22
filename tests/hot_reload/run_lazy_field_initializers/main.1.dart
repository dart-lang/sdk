// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/36c0788137d55c6c77f4b9a8be12e557bc764b1c/runtime/vm/isolate_reload_test.cc#L4810

int myInitialValue = 8 * 7;

class Foo {
  int x = 4;
  int y = myInitialValue++;
}

late Foo value;
late Foo value1;

void validate() {
  // Add field 'y' with side effects and verify that initializers ran lazily.
  Expect.equals(1, hotReloadGeneration);
  Expect.equals(4, value.x);
  Expect.equals(4, value1.x);
  Expect.equals(56, myInitialValue);
  Expect.equals(56, value.y);
  Expect.equals(57, value1.y);
  Expect.equals(58, myInitialValue);
}

Future<void> main() async {
  validate();
  await hotReload();
  validate();
}
/** DIFF **/
/*
@@ -12,18 +12,21 @@
 
 class Foo {
   int x = 4;
+  int y = myInitialValue++;
 }
 
 late Foo value;
 late Foo value1;
 
 void validate() {
-  Expect.equals(0, hotReloadGeneration);
-  value = Foo();
-  value1 = Foo();
+  // Add field 'y' with side effects and verify that initializers ran lazily.
+  Expect.equals(1, hotReloadGeneration);
   Expect.equals(4, value.x);
   Expect.equals(4, value1.x);
   Expect.equals(56, myInitialValue);
+  Expect.equals(56, value.y);
+  Expect.equals(57, value1.y);
+  Expect.equals(58, myInitialValue);
 }
 
 Future<void> main() async {
*/
