// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'issue31767.dart';

const int _private = 3;

class A {
  final int w;
  final _A a;
  A.foo(int x, [int y = _private, int z = _private, this.a = const _A(5)])
      : w = p("x", x) + p("y", y) + p("z", z);
}

class _A {
  final int field;
  const _A(this.field);
}
