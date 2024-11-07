// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/63622f03eeaf72983b2f4957fa84da8062693f00/runtime/vm/isolate_reload_test.cc#L5929

class A {}

class B {}

typedef bool Predicate(B b);

Predicate value = init();
init() => (A a) => true;

String helper() {
  try {
    return value.toString();
  } catch (e) {
    return e.toString();
  }
}

Future<void> main() async {
  Expect.contains('Closure: (A) => bool', helper());

  await hotReload();

  // B is no longer a subtype of A.
  Expect.contains(
      "type '(A) => bool' is not a subtype of type '(B) => bool'", helper());
}
/** DIFF **/
/*
@@ -10,7 +10,7 @@
 
 class A {}
 
-class B extends A {}
+class B {}
 
 typedef bool Predicate(B b);
 
*/
