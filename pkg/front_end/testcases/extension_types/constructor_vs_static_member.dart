// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class1 {
  final int id;
  static int get n => 1;
  Class1.n(this.id); /* Error */
}

class Class2 {
  final int id;
  static int n() => 2;
  const Class2.n(this.id); /* Error */
}

class Class3 {
  final int id;
  static int n() => 3;
  Class3(this.id);
  factory Class3.n(int id) = Class3.new; /* Error */
}

class Class4 {
  final int id;
  static int n = 1;
  Class4.n(this.id); /* Error */
}

extension type ET1(int id) {
  static int get n => 1;
  ET1.n(this.id); /* Error */
}

extension type ET2(int id) {
  static int n() => 2;
  const ET2.n(this.id); /* Error */
}

extension type ET3(int id) {
  static int n() => 3;
  factory ET3.n(int id) = ET3.new; /* Error */
}

extension type ET4(int id) {
  static int n = 1;
  ET4.n(this.id); /* Error */
}