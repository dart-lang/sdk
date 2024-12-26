// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/f34a2ed99fc1b34cedbd974a5801f8d922121126/runtime/vm/isolate_reload_test.cc#L1618

class C {
  foo() => 'new';
}

var c, f1, f2;
helper() {
  f2 = c.foo;
}

Future<void> main() async {
  helper();
  await hotReload();
  helper();
  Expect.equals('new', f1());
  Expect.equals('new', f2());
  Expect.equals(f1, f2);
  Expect.notIdentical(f1, f2);
}
/** DIFF **/
/*
@@ -9,13 +9,12 @@
 // https://github.com/dart-lang/sdk/blob/f34a2ed99fc1b34cedbd974a5801f8d922121126/runtime/vm/isolate_reload_test.cc#L1618
 
 class C {
-  foo() => 'old';
+  foo() => 'new';
 }
 
 var c, f1, f2;
 helper() {
-  c = new C();
-  f1 = c.foo;
+  f2 = c.foo;
 }
 
 Future<void> main() async {
*/
