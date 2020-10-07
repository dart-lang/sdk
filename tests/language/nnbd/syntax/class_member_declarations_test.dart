// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

class A {
  static late final x2;
  static late int x3;
  static late final A x4;
  static late final x6 = 0;
  static late int x7 = 0;
  static late final A? x8 = null;

  covariant late var x13;
  covariant late var x14 = '';

  covariant late double x23;
  covariant late String x24 = '';

  late final x26;
  late int x27;
  late final A x28;
  late final x30 = 0;
  late int x31 = 0;
  late final A? x32 = null;

  List foo() {
    final x41 = true;
    late final x42;
    late final x43 = [], x44 = {};
    return x43;
  }
}

abstract class B {
  m1(
    int some,
    regular,
    covariant parameters, {
    required p1,
    required covariant p3,
    required covariant int p4,
  });
}

main() {
  A? a;
  var s = '' as String?;
  a
    ?..foo().length
    ..x27 = s!.toString().length;
}
