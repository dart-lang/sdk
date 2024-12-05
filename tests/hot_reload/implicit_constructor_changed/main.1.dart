// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/f34a2ed99fc1b34cedbd974a5801f8d922121126/runtime/vm/isolate_reload_test.cc#L690

class A {
  int field = 10;
}

var savedA = A();
helper() {
  return A();
}

Future<void> main() async {
  Expect.equals(20, savedA.field);
  Expect.equals(20, helper().field);
  await hotReload();

  Expect.equals(20, savedA.field);
  Expect.equals(10, helper().field);
}
/** DIFF **/
/*
@@ -9,7 +9,7 @@
 // https://github.com/dart-lang/sdk/blob/f34a2ed99fc1b34cedbd974a5801f8d922121126/runtime/vm/isolate_reload_test.cc#L690
 
 class A {
-  int field = 20;
+  int field = 10;
 }
 
 var savedA = A();
*/
