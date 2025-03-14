// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/d9502e2a906ceeb7c8e9d2e1ff15e2251dae80ce/runtime/vm/isolate_reload_test.cc#L4306

class A {
  final x, y, w;
  const A(this.x, this.y, this.w);
}

var a;

void helper() {
  a = const A(1, null, null);
}

Future<void> main() async {
  helper();
  await hotReload(expectRejection: true);
  helper();
  await hotReload(expectRejection: true);
  helper();
}

/** DIFF **/
/*
 // https://github.com/dart-lang/sdk/blob/d9502e2a906ceeb7c8e9d2e1ff15e2251dae80ce/runtime/vm/isolate_reload_test.cc#L4306
 
 class A {
-  final x, y;
-  const A(this.x, this.y);
+  final x, y, w;
+  const A(this.x, this.y, this.w);
 }
 
 var a;
 
 void helper() {
-  a = const A(1, null);
+  a = const A(1, null, null);
 }
 
 Future<void> main() async {
*/
