// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {
  int get property1; // ok
  void set property1(int i);

  num get property2a; // ok
  void set property2a(int i);

  int get property2b; // ok
  void set property2b(num i);

  String get property3; // error
  void set property3(int i);

  int property4; // ok

  int property5; // ok

  covariant String property6; // ok

  static int get property7 => 0; // ok
  static void set property7(int value) {}

  static int get property8a => 0; // ok
  static void set property8a(num value) {}

  static num get property8b => 0; // ok
  static void set property8b(int value) {}

  static num get property9 => 0; // error
  static void set property9(String value) {}
}

abstract class B1 {
  int get property1;

  int get property2;

  String get property3;

  final int property4;

  final int property5;

  final String property6;

  B1(this.property4, this.property5, this.property6);
}

abstract class B2 implements B1 {
  void set property1(int i); // ok

  void set property2(String i); // error

  void set property3(int i); // error

  void set property4(int i); // ok

  void set property5(String i); // error

  void set property6(int i); // error
}

abstract class C1 {
  void set property1(int i);

  void set property2(String i);

  void set property3(int i);

  int property4;

  String property5;

  int property6;
}

abstract class C2 implements C1 {
  int get property1; // ok

  int get property2; // error

  String get property3; // error

  int get property4; // ok

  // This results in two errors; one for the getter/setter type mismatch and one
  // for the getter override.
  int get property5; // error

  // This results in two errors; one for the getter/setter type mismatch and one
  // for the getter override.
  String get property6; // error
}

abstract class D1 {
  int get property1;

  int get property2;

  String get property3;
}

abstract class D2 {
  void set property1(int i);

  void set property2(String i);

  void set property3(int i);
}

abstract class D3 implements D1, D2 /* error on property2 and property3 */ {}

abstract class D4
    implements D3 /* no need for error on property2 and property3 */ {}

extension Extension<T extends num, S extends T> on int {
  int get property1 => 0; // ok
  void set property1(int i) {}

  num get property2a => 0; // ok
  void set property2a(int i) {}

  int get property2b => 0; // ok
  void set property2b(num i) {}

  String get property3 => ''; // error
  void set property3(int i) {}

  S get property4 => 0; // ok
  void set property4(S i) {}

  S get property5a => 0; // ok
  void set property5a(T i) {}

  T get property5b => 0; // ok
  void set property5b(S i) {}

  String get property6 => ''; // error
  void set property6(S i) {}

  static int get property7 => 0; // ok
  static void set property7(int value) {}

  static int get property8a => 0; // ok
  static void set property8a(num value) {}

  static num get property8b => 0; // ok
  static void set property8b(int value) {}

  static num get property9 => 0; // error
  static void set property9(String value) {}
}

main() {}
