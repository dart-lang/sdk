// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

/// Regression test for a bug that could be the cause for
/// https://github.com/dart-lang/sdk/issues/61341.

/// Accidental invocation of getters during hot reload could trigger side
/// effects during the operation. The throwing getter should never be called.

class C {
  static int get staticGetter => throw 'Do not invoke this getter!';
  static int get anotherStaticGetter => 99;
}

Future<void> main() async {
  Expect.equals(42, C.anotherStaticGetter);
  await hotReload();
  Expect.equals(99, C.anotherStaticGetter);
}

/** DIFF **/
/*
 
 class C {
   static int get staticGetter => throw 'Do not invoke this getter!';
-  static int get anotherStaticGetter => 42;
+  static int get anotherStaticGetter => 99;
 }
 
 Future<void> main() async {
*/
