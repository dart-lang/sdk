// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/a70adce28e53ff8bb3445fe96f3f1be951d8a417/runtime/vm/isolate_reload_test.cc#L5423

class C {
  static var x = 42;
}

helper() {
  return '${C.x}';
}

Future<void> main() async {
  Expect.equals('okay', helper());
  Expect.equals(0, hotReloadGeneration);

  await hotReload();

  Expect.equals('42', helper());
  Expect.equals(1, hotReloadGeneration);
}
/** DIFF **/
/*
@@ -8,10 +8,12 @@
 // Adapted from:
 // https://github.com/dart-lang/sdk/blob/a70adce28e53ff8bb3445fe96f3f1be951d8a417/runtime/vm/isolate_reload_test.cc#L5423
 
-class C {}
+class C {
+  static var x = 42;
+}
 
 helper() {
-  return 'okay';
+  return '${C.x}';
 }
 
 Future<void> main() async {
*/
