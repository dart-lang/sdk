// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

import 'dart:async';

class A {
  Future<int> foo(int x, int y, int z) async => x + y + z;
}

class B extends A {
  Future<int> foo(int x, int y, int z) async {
    var w = await super.foo(x, y, z);
    return w + 1;
  }
}

main() async {
  Expect.equals(7, await new B().foo(1, 2, 3));
}
