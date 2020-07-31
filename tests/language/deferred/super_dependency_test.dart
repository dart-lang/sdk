// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test.
// lib.C.foo has code that references `super.foo=` that does not exist. This
// used to cause a crash.

import "package:expect/expect.dart";
//        ^^^
// [analyzer] STATIC_TYPE_WARNING.UNDEFINED_SUPER_SETTER
// [cfe] Superclass has no setter named 'foo'.
import "super_dependency_lib.dart" deferred as lib;

main() async {
  await lib.loadLibrary();
  Expect.throwsNoSuchMethodError(() => new lib.C().foo());
}
