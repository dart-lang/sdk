// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/1a486499bf73ee5b007abbe522b94869a1f36d02/runtime/vm/isolate_reload_test.cc#L4051

// Tests reload succeeds when type parameters are changed for allocated class.
// Change: Foo<A,B> {a, b} -> Foo<A> {a}
// Validate: return value from main is correct.
// Please note: This test works because no instances are created from Foo.

class Foo<A> {
  var a;
}

Future<void> main() async {
  await hotReload();
}

/** DIFF **/
/*
 // Validate: return value from main is correct.
 // Please note: This test works because no instances are created from Foo.
 
-class Foo<A, B> {
+class Foo<A> {
   var a;
-  var b;
 }
 
 Future<void> main() async {
*/
