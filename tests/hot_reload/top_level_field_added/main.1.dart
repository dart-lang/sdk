// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/36c0788137d55c6c77f4b9a8be12e557bc764b1c/runtime/vm/isolate_reload_test.cc#L449

var value1 = 10;
var value2 = 20;

validate() {
  return '$value1$value2';
}

Future<void> main() async {
  Expect.equals('10', validate());

  await hotReload();

  Expect.equals('1020', validate());
}
/** DIFF **/
/*
@@ -9,9 +9,10 @@
 // https://github.com/dart-lang/sdk/blob/36c0788137d55c6c77f4b9a8be12e557bc764b1c/runtime/vm/isolate_reload_test.cc#L449
 
 var value1 = 10;
+var value2 = 20;
 
 validate() {
-  return '$value1';
+  return '$value1$value2';
 }
 
 Future<void> main() async {
*/
