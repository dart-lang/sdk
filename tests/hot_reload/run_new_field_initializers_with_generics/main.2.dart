// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/63622f03eeaf72983b2f4957fa84da8062693f00/runtime/vm/isolate_reload_test.cc#L5381

class Foo<T> {
  T? x;
  List<T> y = List<T>.empty();
  dynamic z = <T, T>{};
}

late Foo value1;
late Foo value2;

(dynamic, dynamic) helper() {
  return (value1.z, value2.z);
}

Future<void> main() async {
  var (v1, v2) = helper();
  Expect.type<String?>(v1);
  Expect.type<int?>(v2);
  await hotReload();

  (v1, v2) = helper();
  Expect.type<List<String>>(v1);
  Expect.type<List<int>>(v2);
  await hotReload();

  (v1, v2) = helper();
  Expect.type<Map<String, String>>(v1);
  Expect.type<Map<int, int>>(v2);
}
/** DIFF **/
/*
@@ -11,13 +11,14 @@
 class Foo<T> {
   T? x;
   List<T> y = List<T>.empty();
+  dynamic z = <T, T>{};
 }
 
 late Foo value1;
 late Foo value2;
 
 (dynamic, dynamic) helper() {
-  return (value1.y, value2.y);
+  return (value1.z, value2.z);
 }
 
 Future<void> main() async {
*/
