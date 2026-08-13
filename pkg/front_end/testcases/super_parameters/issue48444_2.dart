// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {
  void foo() {}
}

class B extends A {
  void bar(bool t) {
    t ? super.foo() : super.foo();
  }
}

main() {}
