// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

Object? sharedA1;
Object? sharedA2;
Object? sharedA4;
Object? sharedB6;
Object? sharedB7;
Object? sharedValue;

class A1 {
  void m1() {
    print('m1 method called');
  }

  Object? get g2 => sharedValue;
  set s3(Object? value) {
    sharedValue = value;
  }

  int m4(int value) {
    return value % 10;
  }

  int? f1;
  final int f2 = 3;

  void m6() {
    print('m6 called');
  }

  void m7() {
    print('m7 called');
  }
}

class A2 {
  void m1() {
    print('A2.m1 called');
  }
}

abstract interface class A3 {
  int m9(int input); // exposed
  void m6(); // not-exposed
}

class A4 implements A3 {
  @override
  int m9(int input) => input + 10;

  @override
  void m6() {
    print('A4.m6 called');
  }
}

abstract class A5 {
  int m10() => 1;
  int m11() => 1;
  int m12() => 1;
  int m13() => 1;
}

abstract class A7 {
  int m15() => 1;
  int m16() => 1;
  int m17() => 1;
  int m18() => 1;
}
