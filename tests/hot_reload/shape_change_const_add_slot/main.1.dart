// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/368cb645e5ff5baa1d1ed86bfd2e7d818471a652/runtime/vm/isolate_reload_test.cc#L4243

void helper() {
  a = const A(1, null, null);
}

class A {
  final x, y, z;
  const A(this.x, this.y, this.z);
}

var a;

Future<void> main() async {
  helper();
  await hotReload();
  helper();
  await hotReload();
  helper();
}
/** DIFF **/
/*
@@ -8,12 +8,12 @@
 // https://github.com/dart-lang/sdk/blob/368cb645e5ff5baa1d1ed86bfd2e7d818471a652/runtime/vm/isolate_reload_test.cc#L4243
 
 void helper() {
-  a = const A(1);
+  a = const A(1, null, null);
 }
 
 class A {
-  final x;
-  const A(this.x);
+  final x, y, z;
+  const A(this.x, this.y, this.z);
 }
 
 var a;
*/
