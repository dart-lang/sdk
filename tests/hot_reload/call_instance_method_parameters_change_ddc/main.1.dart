// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

var retained;
C? c;

class C {
  int parametersChange(String s) {
    return s.length;
  }
}

helper() {
  return retained!();
}

Future<void> main() async {
  Expect.equals(42, helper());
  await hotReload();
  Expect.throws<TypeError>(
    helper,
    (error) => '$error'.contains("'int' is not a subtype of type 'String'"),
  );
}

/** DIFF **/
/*
 C? c;
 
 class C {
-  int parametersChange(int i) {
-    return i + 10;
+  int parametersChange(String s) {
+    return s.length;
   }
 }
 
 helper() {
-  c = C();
-  retained = () => c!.parametersChange(32);
   return retained!();
 }
 
*/
