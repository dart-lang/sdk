// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/0b221871890a3daf331799aba7409bf299a35cfb/runtime/vm/isolate_reload_test.cc#L6065

typedef bool Predicate(dynamic x, dynamic y);

void expectHelper() {
  bool foo(x) => true;
  Expect.notType<Predicate>(foo);
}

Future<void> main() async {
  expectHelper();
  await hotReload();
  expectHelper();
}
/** DIFF **/
/*
@@ -8,11 +8,11 @@
 // Adapted from:
 // https://github.com/dart-lang/sdk/blob/0b221871890a3daf331799aba7409bf299a35cfb/runtime/vm/isolate_reload_test.cc#L6065
 
-typedef bool Predicate(dynamic x);
+typedef bool Predicate(dynamic x, dynamic y);
 
 void expectHelper() {
   bool foo(x) => true;
-  Expect.type<Predicate>(foo);
+  Expect.notType<Predicate>(foo);
 }
 
 Future<void> main() async {
*/
