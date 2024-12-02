// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/368cb645e5ff5baa1d1ed86bfd2e7d818471a652/runtime/vm/isolate_reload_test.cc#L4210

helper() {
  hash2 = a.hashCode;
}

class A {
  final x, y, z;
  const A(this.x, this.y, this.z);
}

var a, hash1, hash2;

Future<void> main() async {
  helper();
  await hotReload();
  helper();
  Expect.equals(hash1, hash2);
}
/** DIFF **/
/*
@@ -8,14 +8,13 @@
 // Adapted from:
 // https://github.com/dart-lang/sdk/blob/368cb645e5ff5baa1d1ed86bfd2e7d818471a652/runtime/vm/isolate_reload_test.cc#L4210
 
-void helper() {
-  a = const A(1);
-  hash1 = a.hashCode;
+helper() {
+  hash2 = a.hashCode;
 }
 
 class A {
-  final x;
-  const A(this.x);
+  final x, y, z;
+  const A(this.x, this.y, this.z);
 }
 
 var a, hash1, hash2;
*/
