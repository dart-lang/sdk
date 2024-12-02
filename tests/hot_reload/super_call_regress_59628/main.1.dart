// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Regression test for https://github.com/dart-lang/sdk/issues/59628.

class A {
  method() {
    return 'A.method';
  }
}

class B extends A {
  method() {
    return '${super.method()} - B.method';
  }
}

String unrelatedChange() => 'after';

Future<void> main() async {
  Expect.equals('before', unrelatedChange());
  var b = B();
  Expect.equals('A.method - B.method', b.method());
  await hotReload();
  Expect.equals('after', unrelatedChange());
  Expect.equals('A.method - B.method', b.method());
}

/** DIFF **/
/*
@@ -19,7 +19,7 @@
   }
 }
 
-String unrelatedChange() => 'before';
+String unrelatedChange() => 'after';
 
 Future<void> main() async {
   Expect.equals('before', unrelatedChange());
@@ -29,3 +29,4 @@
   Expect.equals('after', unrelatedChange());
   Expect.equals('A.method - B.method', b.method());
 }
+
*/
