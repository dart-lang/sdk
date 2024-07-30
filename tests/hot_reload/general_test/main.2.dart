// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Adapted from:
// https://github.com/dart-lang/sdk/blob/8df8de82b38fae8e9ae1c310fef4f8b735649fd4/pkg/front_end/test/hot_reload_e2e_test.dart

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

import 'b.dart';
import 'c.dart';

f() => "$line part4";

Future<void> main() async {
  // Initial program is valid.
  var last = f();
  Expect.equals('part1 part2', last);
  Expect.equals(0, hotReloadGeneration);
  await hotReload();

  // Reload after leaf library modification.
  last = f();
  Expect.equals('part3 part2', last);
  Expect.equals(1, hotReloadGeneration);
  await hotReload();

  // Reload after non-leaf library modification.
  last = f();
  Expect.equals('part3 part4', last);
  Expect.equals(2, hotReloadGeneration);
  await hotReload();

  // Reload after whole program modification.
  last = f();
  Expect.equals('part5 part6', last);
  Expect.equals(3, hotReloadGeneration);
  await hotReload();

  // Reload top-level field.
  last = f();
  var topLevel = g();
  Expect.equals('part4 part6', last);
  Expect.equals('a', topLevel);
  Expect.equals(4, hotReloadGeneration);
  await hotReload();

  // Reload top-level field.
  last = f();
  topLevel = g();
  Expect.equals('part4 part6', last);
  Expect.equals('ac', topLevel);
  Expect.equals(5, hotReloadGeneration);
}
/** DIFF **/
/*
@@ -11,7 +11,7 @@
 import 'b.dart';
 import 'c.dart';
 
-f() => "$line part2";
+f() => "$line part4";
 
 Future<void> main() async {
   // Initial program is valid.
*/
