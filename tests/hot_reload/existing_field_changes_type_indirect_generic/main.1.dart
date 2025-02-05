// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/bf2fba78e006ce4feac43e514c0b8f3ea9e9fbb8/runtime/vm/isolate_reload_test.cc#L5793

class A {}

class B {}

class Foo {
  List<A> x;
  Foo(this.x);
}

late Foo value;

helper() {
  try {
    return value.x.toString();
  } catch (e) {
    return e.toString();
  }
}

Future<void> main() async {
  Expect.equals('okay', helper());
  Expect.equals(0, hotReloadGeneration);

  await hotReload();

  // B is no longer a subtype of A.
  Expect.contains(
      "type 'List<B>' is not a subtype of type 'List<A>'", helper());
  Expect.equals(1, hotReloadGeneration);
}
/** DIFF **/
/*
@@ -10,7 +10,7 @@
 
 class A {}
 
-class B extends A {}
+class B {}
 
 class Foo {
   List<A> x;
@@ -20,8 +20,11 @@
 late Foo value;
 
 helper() {
-  value = Foo(List<B>.empty());
-  return 'okay';
+  try {
+    return value.x.toString();
+  } catch (e) {
+    return e.toString();
+  }
 }
 
 Future<void> main() async {
*/
