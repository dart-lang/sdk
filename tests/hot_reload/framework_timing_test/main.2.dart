// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

var x = 'Hello Bar';

void main() {
  Expect.equals('Hello Bar', x);
  Expect.equals(2, hotRestartGeneration);

  scheduleMicrotask(() {
    Expect.equals(2, hotRestartGeneration);
  });
  Future<Null>.microtask(() {
    throw x;
  }).catchError((e, stackTrace) {
    Expect.equals("Hello Bar", e);
    Expect.equals(2, hotRestartGeneration);
  }).then((_) {
    Expect.equals(2, hotRestartGeneration);
  });
  Future.delayed(Duration(seconds: 5), () {
    throw Exception('Future from main.2.dart before hot restart. '
        'This should never run.');
  });

  hotRestart();
}
/** DIFF **/
/*
@@ -7,25 +7,25 @@
 import 'package:expect/expect.dart';
 import 'package:reload_test/reload_test_utils.dart';
 
-var x = 'Hello Foo';
+var x = 'Hello Bar';
 
 void main() {
-  Expect.equals('Hello Foo', x);
-  Expect.equals(1, hotRestartGeneration);
+  Expect.equals('Hello Bar', x);
+  Expect.equals(2, hotRestartGeneration);
 
   scheduleMicrotask(() {
-    Expect.equals(1, hotRestartGeneration);
+    Expect.equals(2, hotRestartGeneration);
   });
   Future<Null>.microtask(() {
     throw x;
   }).catchError((e, stackTrace) {
-    Expect.equals("Hello Foo", e);
-    Expect.equals(1, hotRestartGeneration);
+    Expect.equals("Hello Bar", e);
+    Expect.equals(2, hotRestartGeneration);
   }).then((_) {
-    Expect.equals(1, hotRestartGeneration);
+    Expect.equals(2, hotRestartGeneration);
   });
   Future.delayed(Duration(seconds: 5), () {
-    throw Exception('Future from main.1.dart before hot restart. '
+    throw Exception('Future from main.2.dart before hot restart. '
         'This should never run.');
   });
 
*/
