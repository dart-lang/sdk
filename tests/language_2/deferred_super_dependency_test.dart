// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test.
// lib.C.foo has code that references `super.foo=` that does not exist. This
// used to cause a crash.

import "package:expect/expect.dart";
import "deferred_super_dependency_lib.dart" deferred as lib; //# 01: compile-time error

main() async {
  await lib.loadLibrary(); //# 01: continued
  Expect.throwsNoSuchMethodError(() => new lib.C().foo()); //# 01: continued
}
