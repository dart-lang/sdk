// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

import 'b.dart';

f() => "$line part3";

Future<void> main() async {
  var last = f();
  Expect.equals('part1 part2', last);
  Expect.equals(0, hotReloadGeneration);
  await hotReload();

  last = f();
  Expect.equals('part1 part3', last);
  Expect.equals(1, hotReloadGeneration);
  await hotReload();

  last = f();
  Expect.equals('part1 part4', last);
  Expect.equals(2, hotReloadGeneration);
}

/** DIFF **/
/*
 
 import 'b.dart';
 
-f() => "$line part2";
+f() => "$line part3";
 
 Future<void> main() async {
   var last = f();
*/
