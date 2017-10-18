// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test has been modified: it is now ok to use deferred types as long as
// they aren't instantiated.

library regress_23408_test;

import 'package:expect/expect.dart';

import 'regress_23408_lib.dart' deferred as lib;

class A<T> extends C {
  get t => T;
}

class C {
  var v = 55;
  C();
  factory C.c() = lib.K;
  factory C.l() = A<lib.K>;
}

void main() {
  var a = new C.l();
  Expect.equals(lib.K, a.t);
  Expect.throws(() => new C.c());
  lib.loadLibrary().then((_) {
    var b = new C.l();
    Expect.equals(lib.K, b.t);
    var z = new C.c();
    Expect.equals(55, z.v);
  });
}
