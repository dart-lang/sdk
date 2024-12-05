// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/a70adce28e53ff8bb3445fe96f3f1be951d8a417/runtime/vm/isolate_reload_test.cc#L5678

class A {}

class B {}

B value = init();

init() => B();

helper() {
  try {
    return value.toString();
  } catch (e) {
    return e.toString();
  }
}

Future<void> main() async {
  Expect.equals("Instance of 'A'", helper());
  Expect.equals(0, hotReloadGeneration);

  await hotReload();

  Expect.contains(
      "type 'A' is not a subtype of type 'B' of 'function result'", helper());
  Expect.equals(1, hotReloadGeneration);
}
/** DIFF **/
/*
@@ -12,9 +12,9 @@
 
 class B {}
 
-A value = init();
+B value = init();
 
-init() => A();
+init() => B();
 
 helper() {
   try {
*/
