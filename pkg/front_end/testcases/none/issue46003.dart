// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  final Function() foo;
  A(this.foo);

  void bar() {
    foo();

    Function() x = foo;
    x();

    void Function() y = foo;
    y();
  }
}

main() {
  A(() {}).bar();
}
