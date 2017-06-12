// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';

import "deferred_mixin_lib1.dart" deferred as lib1;
import "deferred_mixin_lib2.dart" deferred as lib2;

class NonDeferredMixin {
  foo() => "NonDeferredMixin";
}

class NonDeferredMixin1 {
  foo() => "NonDeferredMixin1";
}

class NonDeferredMixin2 {
  foo() => "NonDeferredMixin2";
}

main() {
  Expect.equals("NonDeferredMixin", new NonDeferredMixin().foo());
  Expect.equals("NonDeferredMixin1", new NonDeferredMixin1().foo());
  Expect.equals("NonDeferredMixin2", new NonDeferredMixin2().foo());
  asyncStart();
  lib1.loadLibrary().then((_) {
    Expect.equals("lib1.Mixin", new lib1.Mixin().foo());
    Expect.equals("A with NonDeferredMixin", new lib1.A().foo());
    Expect.equals("B with lib1.Mixin", new lib1.B().foo());
    Expect.equals("C with NonDeferredMixin1", new lib1.C().foo());
    Expect.equals("D with lib1.Mixin", new lib1.D().foo());
    Expect.equals("E with SharedMixin", new lib1.E().foo());
    lib2.loadLibrary().then((_) {
      Expect.equals("lib2.A with SharedMixin", new lib2.A().foo());
      asyncEnd();
    });
  });
}
