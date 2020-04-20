// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  final int x;
  final int y;
  A(this.y) : x = 42;
  method() {
    print("A.method x: $x y: $y");
    print(this);
    print(this.runtimeType);
  }
}

class B extends A {
  B(x) : super(x);
  method() {
    print("B.method x: $x y: $y");
    super.method();
  }
}

main() {
  A a = new A(87);
  B b = new B(117);
  a.method();
  b.method();
}
