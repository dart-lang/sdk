// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/f34a2ed99fc1b34cedbd974a5801f8d922121126/runtime/vm/isolate_reload_test.cc#L1770

var f1, f2;
foo() => 'new';
getFoo() => foo;

Future<void> main() async {
  var f1 = getFoo();
  await hotReload();

  var f2 = getFoo();
  Expect.equals('new', f1());
  Expect.equals('new', f2());
  Expect.equals(f1, f2);
  Expect.identical(f1, f2);
}
/** DIFF **/
/*
@@ -9,7 +9,7 @@
 // https://github.com/dart-lang/sdk/blob/f34a2ed99fc1b34cedbd974a5801f8d922121126/runtime/vm/isolate_reload_test.cc#L1770
 
 var f1, f2;
-foo() => 'old';
+foo() => 'new';
 getFoo() => foo;
 
 Future<void> main() async {
*/
