// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/f34a2ed99fc1b34cedbd974a5801f8d922121126/runtime/vm/isolate_reload_test.cc#L1656

class C {
  static foo(i) => 'new:$i';
}

var f1;
helper() {
  f1();
}

Future<void> main() async {
  await hotReload();
  Expect.throws<ArgumentError>(helper);
}
/** DIFF **/
/*
@@ -9,11 +9,13 @@
 // https://github.com/dart-lang/sdk/blob/f34a2ed99fc1b34cedbd974a5801f8d922121126/runtime/vm/isolate_reload_test.cc#L1656
 
 class C {
-  static foo() => 'old';
+  static foo(i) => 'new:$i';
 }
 
-var f1 = C.foo;
-helper() {}
+var f1;
+helper() {
+  f1();
+}
 
 Future<void> main() async {
   await hotReload();
*/
