// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  int x;
}

class C extends A {
  void setX(int value) {
    super.x = value;
  }
}

main() {
  A a = new C();
  a.x = 37;
  a.setX(42); //# 01: compile-time error
}
