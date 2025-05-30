// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'dart:_internal' show extractTypeArguments;

class CC<A, B, C, D, E> {}

class X {}

main() {
  test(new CC<X, X, X, X, int>(), int);
  test(new CC<X, X, X, X, String>(), String);
}

test(dynamic a, T) {
  Expect.equals(T, extractTypeArguments<CC>(a, <_1, _2, _3, _4, T>() => T));
}
