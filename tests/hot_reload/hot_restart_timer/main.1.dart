// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

bool beforeRestart = true;
bool calledBeforeRestart = false;
bool calledAfterRestart = false;
void callback(_) {
  if (beforeRestart) {
    calledBeforeRestart = true;
  } else {
    throw Exception('Should never run.');
  }
}

Future<void> main() async {
  Timer.periodic(Duration(milliseconds: 10), callback);
  await new Future.delayed(Duration(milliseconds: 100));
  Expect.isTrue(calledBeforeRestart);

  await hotRestart();
}
/** DIFF **/
/*
@@ -9,14 +9,18 @@
 bool beforeRestart = true;
 bool calledBeforeRestart = false;
 bool calledAfterRestart = false;
-void callback() {
-  throw Exception('Should never run.');
+void callback(_) {
+  if (beforeRestart) {
+    calledBeforeRestart = true;
+  } else {
+    throw Exception('Should never run.');
+  }
 }
 
 Future<void> main() async {
-  Expect.isFalse(calledBeforeRestart);
-  Timer(Duration(milliseconds: 500), callback);
-  Expect.isFalse(calledBeforeRestart);
+  Timer.periodic(Duration(milliseconds: 10), callback);
+  await new Future.delayed(Duration(milliseconds: 100));
+  Expect.isTrue(calledBeforeRestart);
 
   await hotRestart();
 }
*/
