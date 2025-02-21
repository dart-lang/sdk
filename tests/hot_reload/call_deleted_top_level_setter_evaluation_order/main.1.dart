// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/13f5fc6b168d8b6e5843d17fb9ba77f1343a7dfe/runtime/vm/isolate_reload_test.cc#L2949

var retained;

first(flag) {
  if (flag) throw 'first!';
  return 'hello';
}

helper() {
  return retained(true);
}

Future<void> main() async {
  Expect.equals('hello', helper());
  await hotReload();

  Expect.throws(helper, (error) => error.toString().contains('first!'));
}

/** DIFF **/
/*
   return 'hello';
 }
 
-set deleted(x) {}
-
 helper() {
-  retained = (bool flag) => deleted = first(flag);
-  return retained(false);
+  return retained(true);
 }
 
 Future<void> main() async {
*/
