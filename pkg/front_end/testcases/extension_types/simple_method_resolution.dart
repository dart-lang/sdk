// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  void foo() {}
}

extension E on A {
  void bar() => foo();
}

test(A a, E e) {
  a.foo(); // Ok.
  a.bar(); // Ok.
  e.foo(); // Error.
  e.bar(); // Ok.
}

main() {}
