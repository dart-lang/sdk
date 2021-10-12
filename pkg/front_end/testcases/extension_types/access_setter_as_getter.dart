// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

extension E on A {
  void set foo(int value) {}
  int get bar => 42;
}

test(E e) {
  e.foo = 42; // Ok.
  e.bar; // Ok.

  e.foo; // Error.
  e.bar = 42; // Error.
}

main() {}
