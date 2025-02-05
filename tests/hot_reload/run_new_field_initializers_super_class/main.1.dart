// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/640ad1416eaa2779e33f19e11a3249bb4f9d13f9/runtime/vm/isolate_reload_test.cc#L5323

class Super {
  static var foo = 'right';
  var newField = foo;
}

class Foo extends Super {
  static var foo = 'wrong';
}

late Foo value;
String helper() {
  return value.newField;
}

Future<void> main() async {
  Expect.equals('right', Super.foo);
  Expect.equals('wrong', Foo.foo);
  Expect.equals('okay', helper());
  await hotReload();

  Expect.equals('right', helper());
}
/** DIFF **/
/*
@@ -10,6 +10,7 @@
 
 class Super {
   static var foo = 'right';
+  var newField = foo;
 }
 
 class Foo extends Super {
@@ -18,8 +19,7 @@
 
 late Foo value;
 String helper() {
-  value = Foo();
-  return 'okay';
+  return value.newField;
 }
 
 Future<void> main() async {
*/
