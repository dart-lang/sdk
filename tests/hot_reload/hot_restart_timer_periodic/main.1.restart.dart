// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

bool beforeRestart = false;
bool calledBeforeRestart = false;
bool calledAfterRestart = false;
void callback(_) {
  if (beforeRestart) {
    calledBeforeRestart = true;
  } else {
    calledAfterRestart = true;
  }
}

void main() async {
  await new Future.delayed(Duration(milliseconds: 50));
  Expect.isFalse(beforeRestart);
  Expect.isFalse(calledAfterRestart);
}

/** DIFF **/
/*
 import 'package:expect/expect.dart';
 import 'package:reload_test/reload_test_utils.dart';
 
-bool beforeRestart = true;
+bool beforeRestart = false;
 bool calledBeforeRestart = false;
 bool calledAfterRestart = false;
 void callback(_) {
@@ -18,9 +18,7 @@ void callback(_) {
 }
 
 void main() async {
-  Timer.periodic(Duration(milliseconds: 10), callback);
   await new Future.delayed(Duration(milliseconds: 50));
-  Expect.isTrue(beforeRestart);
-  Expect.isTrue(calledBeforeRestart);
-  await hotRestart();
+  Expect.isFalse(beforeRestart);
+  Expect.isFalse(calledAfterRestart);
 }
*/
