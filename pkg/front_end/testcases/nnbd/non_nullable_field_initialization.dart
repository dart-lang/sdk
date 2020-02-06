// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo {}

int topLevelField; // Error.

class A {
  static int staticFieldOfA; // Error.
  int fieldOfA; // Error.
  A.foo();
  A.bar(this.fieldOfA);
}

class B<X extends Object?, Y extends Object> {
  X fieldOfB; // Error.
  Y fieldOfB2; // Error.
  B.foo();
  B.bar(this.fieldOfB, this.fieldOfB2);
}

mixin M {
  static int staticFieldOfM; // Error.
  int fieldOfM; // Error.
}

mixin N<X extends Object?, Y extends Object> {
  X fieldOfN; // Error.
  Y fieldOfN2; // Error.
}

extension P on Foo {
  static int staticFieldOfE; // Error.
}

int? nullableTopLevelField; // Not an error.
late int lateTopLevelField; // Not an error.
int topLevelFieldWithInitializer = 42; // Not an error.

class C<X extends Object?, Y extends Object> {
  static int? staticFieldOfX; // Not an error.
  static int staticFieldOfXInitialized = 42; // Not an error.
  X? fieldOfX; // Not an error.
  int? fieldOfX2; // Not an error.
  dynamic fieldOfX3; // Not an error.
  Null fieldOfX4; // Not an error.
  int Function()? fieldOfX5; // Not an error.
  Y? fieldOfX6; // Not an error.
  static late int lateStaticFieldOfC; // Not an error.
  late int fieldOfC7; // Not an error.
  late X fieldOfC8; // Not an error.
  late Y fieldOfC9; // Not an error.
  int fieldOfC10; // Not an error.

  C.foo(this.fieldOfC10);
  C.bar(this.fieldOfC10);
}

mixin L<X extends Object?, Y extends Object> {
  static int? staticFieldOfL; // Not an error.
  static int staticFieldOfLInitialized = 42; // Not an error
  X? fieldOfL; // Not an error.
  int? fieldOfL2; // Not an error.
  dynamic fieldOfL3; // Not an error.
  Null fieldOfL4; // Not an error.
  int Function()? fieldOfL5; // Not an error.
  Y? fieldOfL6; // Not an error.
  static late int lateStaticFieldOfM; // Not an error.
  late int fieldOfM7; // Not an error.
  late X fieldOfM8; // Not an error.
  late Y fieldOfM9; // Not an error.
}

extension Q on Foo {
  static int? staticFieldOfQ; // Not an error.
  static late int lateStaticFieldOfQ; // Not an error.
  static int staticFieldOfQInitialized = 42; // Not an error.
}

main() {}
