// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int get property1 => 0; // ok
void set property1(int value) {}

int get property2 => 0; // ok
void set property2(num value) {}

num get property3 => 0; // error
void set property3(int value) {}

abstract class A {
  int get property1; // ok
  void set property1(int i);

  int get property2; // ok
  void set property2(int i);

  num get property3; // error
  void set property3(int i);

  int property4 = 0; // ok

  int property5 = 0; // ok

  covariant num property6 = 0; // ok

  static int get property7 => 0; // ok
  static void set property7(int value) {}

  static int get property8 => 0; // ok
  static void set property8(num value) {}

  static num get property9 => 0; // error
  static void set property9(int value) {}
}

abstract class B1 {
  int get property1;

  int get property2;

  num get property3;

  final int property4;

  final int property5;

  final num property6;

  B1(this.property4, this.property5, this.property6);
}

abstract class B2 implements B1 {
  void set property1(int i); // ok

  void set property2(num i); // ok

  void set property3(int i); // error

  void set property4(int i); // ok

  void set property5(num i); // ok

  void set property6(int i); // error
}

abstract class C1 {
  void set property1(int i);

  void set property2(num i);

  void set property3(int i);

  int property4 = 0;

  num property5 = 0;

  int property6 = 0;
}

abstract class C2 implements C1 {
  int get property1; // ok

  int get property2; // ok

  num get property3; // error

  int get property4; // ok

  int get property5; // ok

  // This results in two errors; one for the getter/setter type mismatch and one
  // for the getter override.
  num get property6; // error
}

abstract class D1 {
  int get property1;

  int get property2;

  num get property3;
}

abstract class D2 {
  void set property1(int i);

  void set property2(num i);

  void set property3(int i);
}

abstract class D3 implements D1, D2 /* error on property3 */ {}

abstract class D4 implements D3 /* no need for error on property3 */ {}

extension Extension<T, S extends T> on int {
  int get property1 => 0; // ok
  void set property1(int i) {}

  int get property2 => 0; // ok
  void set property2(num i) {}

  num get property3 => 0; // error
  void set property3(int i) {}

  S get property4 => 0; // ok
  void set property4(S i) {}

  S get property5 => 0; // ok
  void set property5(T i) {}

  T get property6 => 0; // error
  void set property6(S i) {}

  static int get property7 => 0; // ok
  static void set property7(int value) {}

  static int get property8 => 0; // ok
  static void set property8(num value) {}

  static num get property9 => 0; // error
  static void set property9(int value) {}
}

main() {}
