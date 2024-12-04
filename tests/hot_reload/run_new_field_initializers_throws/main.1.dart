// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/640ad1416eaa2779e33f19e11a3249bb4f9d13f9/runtime/vm/isolate_reload_test.cc#L5127

class Foo {
  int x = 4;
  int y = throw 'field throws';
}

late Foo value;

int helper() {
  return value.y;
}

Future<void> main() async {
  Expect.equals(4, helper());
  await hotReload();

  // Verify that we ran field initializers on throwing fields added to existing
  // instances.
  Expect.throws(() => helper(), (e) => '$e' == 'field throws');
}
/** DIFF **/
/*
@@ -10,13 +10,13 @@
 
 class Foo {
   int x = 4;
+  int y = throw 'field throws';
 }
 
 late Foo value;
 
 int helper() {
-  value = Foo();
-  return value.x;
+  return value.y;
 }
 
 Future<void> main() async {
*/
