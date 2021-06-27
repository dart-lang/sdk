// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// dart2jsOptions=--strong

import 'package:expect/expect.dart';
import 'deferred_function_types_lib1.dart' deferred as lib1;
import 'deferred_function_types_lib2.dart' deferred as lib2;

main() async {
  await lib2.loadLibrary();
  Expect.isFalse(lib2.method4() is Object Function(String, String));
  Expect.isTrue(lib2.test4(lib2.method4()));
  await lib1.loadLibrary();
  Expect.isTrue(lib1.test3(lib1.method3()));
  Expect.isFalse(lib1.method3() is Object Function(String));
}
