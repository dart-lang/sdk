// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

void foo(int a, int b) => a + b;

Future<void> main() async {
  void Function() bar() {
    return () => foo(3, 4);
  }

  final f = bar();
  await hotReload();
  Expect.throws<NoSuchMethodError>(f);
}

/** DIFF **/
/*
@@ -5,14 +5,15 @@
 import 'package:expect/expect.dart';
 import 'package:reload_test/reload_test_utils.dart';
 
-void foo(int a) => a + 1;
+void foo(int a, int b) => a + b;
 
 Future<void> main() async {
   void Function() bar() {
-    return () => foo(3);
+    return () => foo(3, 4);
   }
 
   final f = bar();
   await hotReload();
   Expect.throws<NoSuchMethodError>(f);
 }
+
*/
