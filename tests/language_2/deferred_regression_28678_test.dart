// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that await after deferred loading works as expected.

import 'dart:async';
import "package:expect/expect.dart";
import 'deferred_regression_28678_lib.dart' deferred as lib;

class A {
  m() => "here";
}

f(a, b) => new Future.microtask(() {});

class R {
  Future test_deferred() async {
    var a = new A();
    await lib.loadLibrary();
    await f(lib.Clazz, lib.v);
    Expect.equals("here", a.m());
  }
}

main() async {
  await new R().test_deferred();
}
