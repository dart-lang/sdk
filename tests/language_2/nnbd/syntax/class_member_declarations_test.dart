// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

class A {
  static late x1; //# 01: syntax error
  static late final x2;
  static late int x3;
  static late final A x4;
  static late x5 = 0; //# 02: syntax error
  static late final x6 = 0;
  static late int x7 = 0;
  static late final A? x8 = null;

  static final late x9; //# 03: syntax error
  static final late A x10; //# 04: syntax error
  static final late x11 = 0; //# 05: syntax error
  static final late A x12 = null; //# 06: syntax error

  covariant late var x13;
  covariant late var x14 = '';
  covariant late x15; //# 07: syntax error
  covariant late x16 = ''; //# 08: syntax error

  late covariant var x17; //# 09: syntax error
  late covariant var x18 = '';  //# 10: syntax error
  late covariant x19; //# 11: syntax error
  late covariant x20 = ''; //# 12: syntax error

  covariant var late x21; //# 13: syntax error
  covariant var late x22 = '';  //# 14: syntax error

  covariant late double x23;
  covariant late String x24 = '';

  covariant double late x23; //# 15: syntax error
  covariant String late x24 = ''; //# 16: syntax error

  late x25; //# 17: syntax error
  late final x26;
  late int x27;
  late final A x28;
  late x29 = 0; //# 18: syntax error
  late final x30 = 0;
  late int x31 = 0;
  late final A? x32 = null;

  final late x33; //# 19: syntax error
  int late x34; //# 20: syntax error
  var late x35; //# 21: syntax error
  final late A x36; //# 22: syntax error
  final late x37 = 0; //# 23: syntax error
  int late x38 = 0; //# 24: syntax error
  var late x39 = 0; //# 25: syntax error
  final late A? x40 = null; //# 26: syntax error

  List foo() {
    final x41 = true;
    late final x42;
    late final x43 = [], x44 = {};
    return x43;
  }
}

abstract class B {
  m1(int some, regular, covariant parameters, {
      required p1,
      // required p2 = null, // Likely intended to be an error.
      required covariant p3,
      required covariant int p4,
  });
}

main() {
  A? a;
  String? s = '';
  a?..foo().length..x27 = s!..toString().length;
}
