// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

import 'dart:async';

class A {
  Future/*<T>*/ foo/*<T>*/(/*=T*/ x) async => x;
}

class B extends A {
  Future<int> bar() async {
    var x = await super.foo(41);
    return x + 1;
  }
}

main() async {
  Expect.equals(42, await new B().bar());
}
