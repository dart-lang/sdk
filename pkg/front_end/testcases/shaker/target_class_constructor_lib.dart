// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

class A {
  int field;

  A();
  A.namedConstructor();

  void method() {}
}

class B extends A {
  int field;

  B();
  B.namedConstructor() : field = 0;

  void method() {}
}
