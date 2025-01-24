// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/be2aabd91c67f7f331c49cb74e18fe5e469f04db/runtime/vm/isolate_reload_test.cc#L6456
// Regression test for https://github.com/dart-lang/sdk/issues/51835

enum Bar { bar }

class Foo {
  int? a;
  String? b;
  toString() => 'foo';
}

helper() {
  return Foo().toString();
}

Future<void> main() async {
  Expect.equals('foo', helper());
  await hotReload();

  // Modification of an imported library propagates to the importing library.
  Expect.equals('foo', helper());
}

/** DIFF **/
/*
@@ -13,6 +13,7 @@
 
 class Foo {
   int? a;
+  String? b;
   toString() => 'foo';
 }
 
*/
