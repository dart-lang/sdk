// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/f34a2ed99fc1b34cedbd974a5801f8d922121126/runtime/vm/isolate_reload_test.cc#L1693

class C {}

var f1;
helper() {
  f1();
}

Future<void> main() async {
  helper();
  await hotReload();
  Expect.throws<NoSuchMethodError>(
      helper,
      (err) =>
          '$err'.contains("No static method 'foo' declared in class 'C'."));
}
/** DIFF **/
/*
@@ -8,13 +8,11 @@
 // Adapted from:
 // https://github.com/dart-lang/sdk/blob/f34a2ed99fc1b34cedbd974a5801f8d922121126/runtime/vm/isolate_reload_test.cc#L1693
 
-class C {
-  static foo({String bar = 'bar'}) => 'old';
-}
+class C {}
 
 var f1;
 helper() {
-  f1 = C.foo;
+  f1();
 }
 
 Future<void> main() async {
*/
