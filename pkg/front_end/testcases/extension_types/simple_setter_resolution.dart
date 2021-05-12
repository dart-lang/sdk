// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  void set foo(int value) {}
}

extension E on A {
  void set bar(int value) {}
}

test(A a, E e) {
  a.foo = 42; // Ok.
  a.bar = 42; // Ok.
  e.foo = 42; // Error.
  e.bar = 42; // Ok.
}

main() {}
