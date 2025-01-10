// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/f34a2ed99fc1b34cedbd974a5801f8d922121126/runtime/vm/isolate_reload_test.cc#L1867

invoke(f, a) {
  return f(a);
}

var f, r1, r2;

class C {
  foo(x, y, z) => x + y + z;
}

helper() {
  r2 = invoke(f, 1);
  return '$r1 $r2';
}

Future<void> main() async {
  helper();
  await hotReload();
  Expect.throws<NoSuchMethodError>(helper);
}

/** DIFF **/
/*
@@ -15,13 +15,12 @@
 var f, r1, r2;
 
 class C {
-  foo(x) => x;
+  foo(x, y, z) => x + y + z;
 }
 
 helper() {
-  var c = C();
-  f = c.foo;
-  r1 = invoke(f, 1);
+  r2 = invoke(f, 1);
+  return '$r1 $r2';
 }
 
 Future<void> main() async {
@@ -29,3 +28,4 @@
   await hotReload();
   Expect.throws<NoSuchMethodError>(helper);
 }
+
*/
