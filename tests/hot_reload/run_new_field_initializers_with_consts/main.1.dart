// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/368cb645e5ff5baa1d1ed86bfd2e7d818471a652/runtime/vm/isolate_reload_test.cc#L5371

void helper() {
  Expect.identical(a, value.a);
  Expect.identical(b, value.b);
  Expect.identical(c, value.c);
  Expect.identical(d, value.d);
}

class C {
  final x;
  const C(this.x);
}

var a = const C(const C(1));
var b = const C(const C(2));
var c = const C(const C(3));
var d = const C(const C(4));

class Foo {
  var d = const C(const C(4));
  var c = const C(const C(3));
  var b = const C(const C(2));
  var a = const C(const C(1));
}

late Foo value;

Future<void> main() async {
  value = Foo();
  a;
  b;
  c;
  d;
  await hotReload();
  helper();
}
/** DIFF **/
/*
@@ -9,7 +9,10 @@
 // https://github.com/dart-lang/sdk/blob/368cb645e5ff5baa1d1ed86bfd2e7d818471a652/runtime/vm/isolate_reload_test.cc#L5371
 
 void helper() {
-  throw Exception('This should never run.');
+  Expect.identical(a, value.a);
+  Expect.identical(b, value.b);
+  Expect.identical(c, value.c);
+  Expect.identical(d, value.d);
 }
 
 class C {
@@ -22,7 +25,12 @@
 var c = const C(const C(3));
 var d = const C(const C(4));
 
-class Foo {}
+class Foo {
+  var d = const C(const C(4));
+  var c = const C(const C(3));
+  var b = const C(const C(2));
+  var a = const C(const C(1));
+}
 
 late Foo value;
 
*/
