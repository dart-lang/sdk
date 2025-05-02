// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {
  late int property4; // ok

  late int? property5; // ok

  covariant late int property6; // ok

  A(this.property4, this.property5, this.property6);
}

abstract class B1 {
  late final int property4;

  late final int property5;

  late final int? property6;

  B1(this.property4, this.property5, this.property6);
}

abstract class B2 implements B1 {
  void set property4(int i); // ok

  void set property5(int? i); // ok

  void set property6(int i); // error
}

abstract class C1 {
  late int property4;

  late int property5;

  late int property6;

  C1(this.property4, this.property5, this.property6);
}

abstract class C2 implements C1 {
  int get property4; // ok

  int get property5; // ok

  // This results in two errors; one for the getter/setter type mismatch and one
  // for the getter override.
  int? get property6; // error
}

main() {}
