// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

class A {
  static int publicStaticField;
  static int _privateStaticField;

  int publicInstanceField;
  int _privateInstanceField;

  A();

  A.publicConstructor();
  A._privateConstructor();

  factory A.publicFactory() => null;
  factory A._privateFactory() => null;

  static void publicStaticMethod() {}
  static void _privateStaticMethod() {}

  void publicInstanceMethod() {}
  void _privateInstanceMethod() {}
}

class B {
  int field;
}
