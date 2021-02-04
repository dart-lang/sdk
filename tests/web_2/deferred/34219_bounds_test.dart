// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7
// dart2jsOptions=--omit-implicit-checks

// Tests that generic function type bounds are walked as dependencies of a
// closure. If the generic function bounds are not visited, SystemMessage is
// placed in the main unit while it's superclass GeneratedMessage is placed in a
// deferred part.

import '34219_bounds_lib1.dart' deferred as lib1;
import '34219_bounds_lib3.dart' deferred as lib3;

main() async {
  await lib1.loadLibrary();
  lib1.test1();
  await lib3.loadLibrary();
  lib3.test3();
  if (lib1.g is bool Function(Object, Object)) print('!');
}
