// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regression test for https://github.com/dart-lang/sdk/issues/52409.

import 'package:expect/expect.dart';

import "package:expect/static_type_helper.dart";

class A {
  Never get getterThatReturnsNever => throw 0;
}

void f(Object? x) {
  int? y = 0; // implicitly promotes to `int`
  switch (x) {
    case A(getterThatReturnsNever: _):
      y = null;
    default:
  }
  // `y = null` was unreachable, so `y` should still be promoted to `int`
  y.expectStaticType<Exactly<int>>();
}

void main() {
  f(0);
}
