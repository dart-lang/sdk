// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:expect/expect.dart';

final bool alwaysFalse = int.parse('1') == 2;

class A {
  @pragma("vm:never-inline")
  void bar(/* unboxed */ int? x) => Expect.isTrue(x!.isOdd);
}

class B {
  @pragma("vm:never-inline")
  void bar(/* boxed */ int? x) => Expect.isTrue(x!.isOdd);
}

class C extends A implements B {}

main() {
  final Random r = Random();
  if (alwaysFalse) {
    A().bar(r.nextInt(10));
    B().bar(r.nextInt(10));
    B().bar(null);
  }
  final List<B> l = [B(), C()];
  for (B b in l) {
    b.bar(13);
  }
}
