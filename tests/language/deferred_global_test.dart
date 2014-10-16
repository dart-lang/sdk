// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';

import "deferred_global_lib.dart" deferred as lib;

void main() {
  asyncStart();
  lib.loadLibrary().then((_) {
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

    Expect.equals(2, lib.sideEffectCounter);
    asyncEnd();
  });
}
