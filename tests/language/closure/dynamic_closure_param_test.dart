// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Arg {}

abstract class Base<T> {
  void foo(T a);
}

class A extends Base<Arg> {
  @override
  void foo(Arg a, [String? b]) {
    print(a);
    print(b);
  }
}

class B extends A {
  @override
  void foo(Arg a, [String? b, int c = 0]) {
    print(a);
    print(b);
    print(c);
  }
}

void check(void Function(Arg) closure) {
  closure(Arg());
}

void main() {
  final closure = A().foo;
  check(closure);
  B().foo(Arg(), 'b', 3);
}
