// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Interface {
  void methodInInterface();
  int fieldInInterface;
  static final int staticFieldInInterface = 1;
}

class Superclass {
  Superclass() {}

  void methodInSuperclass() {}
  int fieldInSuperclass;
  static void staticMethodInSuperclass() {}
  static int staticFieldInSuperclass;
}

class ClassWithSupertypes extends Superclass implements Interface {
  ClassWithSupertypes() : super() {}

  void method() {}
  int field;
  static void staticMethod() {}
  static int staticField;
}
