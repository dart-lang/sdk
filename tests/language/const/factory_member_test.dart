// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';
import 'package:expect/expect.dart';

abstract class A {
  A.named(this.x5);
  const factory A() = B;

  // No constant expression will evaluate to an instance of `A`, so
  // there is no need to live up to the constant related constraints,
  // we can have instance variables of various kinds, even mutable:

  final List<Never> x1 = [];
  abstract String x2;
  late final int x3 = Random().nextInt(10000);
  late final int x4;
  double? x5;
}

class B implements A {
  const B([this.x5 = 0.57721566490153286]) : x1 = const [];

  // Implement the interface of `A` appropriately for a constant.

  final List<Never> x1;

  final String x2 = 'B.x2';
  set x2(String _) {}

  int get x3 => 42;

  int get x4 => -42;
  set x4(_) {}

  final double? x5;
  set x5(double? _) {}
}

void main() {
  const A();
  const B(2.1);
  Expect.isTrue(identical(const B(0.57721566490153286), const A()));
}
