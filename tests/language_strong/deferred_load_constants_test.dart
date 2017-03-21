// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart version of two-argument Ackermann-Peter function.

library deferred_load_constants;

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import "deferred_load_constants.dart" deferred as foo;
import "deferred_load_constants.dart";

main() {
  asyncStart();
  Expect.throws(() => foo.c);
  Expect.throws(() => foo.C);
  Expect.throws(() => foo.funtype);
  Expect.throws(() => foo.toplevel);
  foo.loadLibrary().whenComplete(() {
    // Reading constant declarations through deferred prefix works.
    Expect.identical(c, foo.c);
    Expect.identical(C, foo.C);
    Expect.identical(funtype, foo.funtype);
    Expect.identical(toplevel, foo.toplevel);
    Expect.identical(C.staticfun, foo.C.staticfun);
    // Access through deferred prefix is not a constant expression.
    Expect.throws(() => const [foo.c]); //           //# 01: compile-time error
    Expect.throws(() => const [foo.C]); //           //# 02: compile-time error
    Expect.throws(() => const [foo.funtype]); //     //# 03: compile-time error
    Expect.throws(() => const [foo.toplevel]); //    //# 04: compile-time error
    Expect.throws(() => const [foo.C.staticfun]); // //# 05: compile-time error

    asyncEnd();
  });
}
