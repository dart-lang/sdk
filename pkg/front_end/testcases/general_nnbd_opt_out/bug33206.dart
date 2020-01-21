// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

import 'dart:async';

class X {
  final x;
  final y;

  X(this.x, this.y);

  toString() => "X($x, $y)";
}

class Y {
  f(_) {}
}

Future<List<Object>> f1() async {
  return [1];
}

List<Object> f2() => [2];

Future<Object> f3() async {
  return 3;
}

Future<X> foo() async {
  return X(Y()..f(await f1())..f(f2()), await f3());
}

Future<void> main() async {
  print(await foo());
}
