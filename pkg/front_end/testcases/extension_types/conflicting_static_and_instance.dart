// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C1 {
  void x() {} // Ok
}

class C2 implements C1 {
  static int get x => 1; // Error
}

extension type I1(int id) {
  void x() {} // Ok
}

extension type I2(int id1) {}

extension type I3(int id) {
  int get property => 42;
}

extension type I4(int id) {
  static void set property(int value) {}
}

extension type ET1(int id) implements I1 {
  static int get x => 1; // Error
}

extension type ET2(int id) implements I1 {
  static int x() => 2; // Error
}

extension type ET3(int id) implements I1 {
  static void set x(int i) {} // Error
}

extension type ET4(int id) implements I1 {
  static int x = 4; // Error
}

extension type ET5(int id) implements I2 {
  static int id1() => 2; // Ok
}

extension type ET6(int id) implements I2 {
  static int get id1 => 2; // Error
}

extension type ET7(int id) implements I2 {
  static int id1 = 5; // Ok
}

extension type ET8(int id) implements I2 {
  static void set id1(int id) {} // Error
}

extension type ET9(int id) /* Error */ implements I3, I4 {}

extension type ET10(int id) implements I3 {
  static void set property(int value) {} /* Error */
}

extension type ET11(int id) implements I4 {
  int get property => 42; /* Error */
}