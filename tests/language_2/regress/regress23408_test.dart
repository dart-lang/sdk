// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library regress_23408_test;

import 'package:expect/expect.dart';

import 'regress23408_lib.dart' deferred as lib;

class C {
  var v = 55;
  C();
  factory C.c() = lib.K;
}

void main() {
  lib.loadLibrary().then((_) {
    var z = new C.c();
    Expect.equals(55, z.v);
  });
}
