// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--strong

import 'package:expect/expect.dart';
import 'deferred_function_types_lib1.dart' deferred as lib1;
import 'deferred_function_types_lib2.dart' deferred as lib2;

main() async {
  await lib2.loadLibrary();
  Expect.isFalse(lib2.method4() is Object Function(Null));
  Expect.isTrue(lib2.method4() is Object Function(Null, Null));
  await lib1.loadLibrary();
  Expect.isTrue(lib1.method3() is Object Function(Null));
  Expect.isFalse(lib1.method3() is Object Function(Null, Null));
}
