// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/63622f03eeaf72983b2f4957fa84da8062693f00/runtime/vm/isolate_reload_test.cc#L5493

// Note: The original VM test checks for allocated objects on the heap after a
// hot reload. There isn't an obvious web analogue, so we've left this off
// unless this side effect becomes visible across platforms.

class C {
  int value = 42;
}

class Foo {}

late var closure;

helper() {}

Future<void> main() async {
  helper();
  Expect.equals(42, closure());
  await hotReload();

  Expect.throws(closure);
}
/** DIFF **/
/*
@@ -16,15 +16,11 @@
   int value = 42;
 }
 
-class Foo {
-  static var x = C();
-}
+class Foo {}
 
 late var closure;
 
-helper() {
-  closure = () => Foo.x.value;
-}
+helper() {}
 
 Future<void> main() async {
   helper();
*/
