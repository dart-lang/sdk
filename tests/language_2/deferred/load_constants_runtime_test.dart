// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart version of two-argument Ackermann-Peter function.

library deferred_load_constants;

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import "load_constants.dart" deferred as foo;
import "load_constants.dart";

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






    asyncEnd();
  });
}
