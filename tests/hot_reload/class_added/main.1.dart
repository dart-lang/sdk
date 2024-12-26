// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/f34a2ed99fc1b34cedbd974a5801f8d922121126/runtime/vm/isolate_reload_test.cc#L561

helper() {
  return A().toString();
}

class A {
  toString() => 'hello from A';
}

Future<void> main() async {
  Expect.equals('hello', helper());
  await hotReload();

  Expect.equals('hello from A', helper());
}
/** DIFF **/
/*
@@ -9,7 +9,11 @@
 // https://github.com/dart-lang/sdk/blob/f34a2ed99fc1b34cedbd974a5801f8d922121126/runtime/vm/isolate_reload_test.cc#L561
 
 helper() {
-  return 'hello';
+  return A().toString();
+}
+
+class A {
+  toString() => 'hello from A';
 }
 
 Future<void> main() async {
*/
