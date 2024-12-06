// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/f34a2ed99fc1b34cedbd974a5801f8d922121126/runtime/vm/isolate_reload_test.cc#L585

var list = <dynamic>[];
helper() {
  return list[0].toString();
}

Future<void> main() async {
  Expect.equals('hello from A', helper());
  await hotReload();

  Expect.equals('hello from A', helper());
}
/** DIFF **/
/*
@@ -8,12 +8,8 @@
 // Adapted from:
 // https://github.com/dart-lang/sdk/blob/f34a2ed99fc1b34cedbd974a5801f8d922121126/runtime/vm/isolate_reload_test.cc#L585
 
-class A {
-  toString() => 'hello from A';
-}
 var list = <dynamic>[];
 helper() {
-  list.add(A());
   return list[0].toString();
 }
 
*/
