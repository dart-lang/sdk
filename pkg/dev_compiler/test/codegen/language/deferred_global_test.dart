// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';

import "deferred_global_lib.dart" deferred as lib;

var nonDeferredGlobal = const {};

void main() {
  nonDeferredGlobal = null;
  asyncStart();
  lib.loadLibrary().then((_) {
    // Ensure non-deferred globals are not reset when loading a deferred
    // library.
    Expect.equals(null, nonDeferredGlobal);

    Expect.equals("finalConstGlobal", lib.finalConstGlobal);
    Expect.equals(0, lib.sideEffectCounter);
    Expect.equals("finalNonConstGlobal", lib.finalNonConstGlobal);
    Expect.equals(1, lib.sideEffectCounter);
    Expect.equals("finalConstGlobal", lib.finalConstGlobal);
    Expect.equals("finalNonConstGlobal", lib.finalNonConstGlobal);
    Expect.equals("lazyConstGlobal", lib.lazyConstGlobal);
    Expect.equals(1, lib.sideEffectCounter);
    Expect.equals("lazyNonConstGlobal", lib.lazyNonConstGlobal);
    Expect.equals(2, lib.sideEffectCounter);
    Expect.equals("finalConstGlobal", lib.readFinalConstGlobal());
    Expect.equals("finalNonConstGlobal", lib.readFinalNonConstGlobal());
    Expect.equals("lazyConstGlobal", lib.readLazyConstGlobal());
    Expect.equals("lazyNonConstGlobal", lib.readLazyNonConstGlobal());

    lib.lazyConstGlobal = "lazyConstGlobal_mutated";
    lib.lazyNonConstGlobal = "lazyNonConstGlobal_mutated";
    Expect.equals("lazyConstGlobal_mutated", lib.lazyConstGlobal);
    Expect.equals("lazyNonConstGlobal_mutated", lib.lazyNonConstGlobal);
    Expect.equals("lazyConstGlobal_mutated", lib.readLazyConstGlobal());
    Expect.equals("lazyNonConstGlobal_mutated", lib.readLazyNonConstGlobal());
    Expect.equals(2, lib.sideEffectCounter);

    lib.writeLazyConstGlobal("lazyConstGlobal_mutated2");
    lib.writeLazyNonConstGlobal("lazyNonConstGlobal_mutated2");
    Expect.equals("lazyConstGlobal_mutated2", lib.lazyConstGlobal);
    Expect.equals("lazyNonConstGlobal_mutated2", lib.lazyNonConstGlobal);
    Expect.equals("lazyConstGlobal_mutated2", lib.readLazyConstGlobal());
    Expect.equals("lazyNonConstGlobal_mutated2", lib.readLazyNonConstGlobal());

    Expect.mapEquals({}, lib.lazyConstGlobal2);
    lib.const1Global = 0;
    Expect.equals(2, lib.sideEffectCounter);
    Expect.equals(0, lib.const1Global);
    // Try loading the deferred library again, should not reset the globals.
    lib.loadLibrary().then((_) {
      Expect.equals(0, lib.const1Global);
      asyncEnd();
    });
  });
}
