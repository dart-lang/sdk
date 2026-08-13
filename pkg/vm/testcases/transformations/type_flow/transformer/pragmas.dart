// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  final int x;
  const A(this.x);
}

class B {
  final int y;
  const B(this.y);
}

class C {
  final int z;
  const C(this.z);
}

@pragma("test1", A(10))
class Foo {
  @pragma("test2", {3: B(11), 4: 'hey'})
  void bar() {
    @pragma("test3", C(12))
    void bazz() {}

    bazz();
  }
}

main() {
  Foo().bar();
}
