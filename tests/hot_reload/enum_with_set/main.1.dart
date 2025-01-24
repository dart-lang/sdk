// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/be2aabd91c67f7f331c49cb74e18fe5e469f04db/runtime/vm/isolate_reload_test.cc#L6537

enum Enum2 { member1, member2 }

enum Enum1 {
  member1({Enum2.member1, Enum2.member2}),
  member2({Enum2.member2}),
  member3({Enum2.member1}),
  member4({Enum2.member2, Enum2.member1}),
  member5({Enum2.member1}),
  member6({Enum2.member1});

  const Enum1(this.set);
  final Set<Enum2> set;
}

var retained;
helper(e) {
  return switch (e as Enum1) {
    Enum1.member1 => 'a',
    Enum1.member2 => 'b',
    Enum1.member3 => 'c',
    Enum1.member4 => 'd',
    Enum1.member5 => 'e',
    Enum1.member6 => 'f',
  };
}

Future<void> main() async {
  retained = Enum1.member4;
  await hotReload();
  Expect.equals('d', helper(retained));
}

/** DIFF **/
/*
@@ -8,6 +8,8 @@
 // Adapted from:
 // https://github.com/dart-lang/sdk/blob/be2aabd91c67f7f331c49cb74e18fe5e469f04db/runtime/vm/isolate_reload_test.cc#L6537
 
+enum Enum2 { member1, member2 }
+
 enum Enum1 {
   member1({Enum2.member1, Enum2.member2}),
   member2({Enum2.member2}),
@@ -20,10 +22,17 @@
   final Set<Enum2> set;
 }
 
-enum Enum2 { member1, member2 }
-
 var retained;
-helper(e) {}
+helper(e) {
+  return switch (e as Enum1) {
+    Enum1.member1 => 'a',
+    Enum1.member2 => 'b',
+    Enum1.member3 => 'c',
+    Enum1.member4 => 'd',
+    Enum1.member5 => 'e',
+    Enum1.member6 => 'f',
+  };
+}
 
 Future<void> main() async {
   retained = Enum1.member4;
*/
