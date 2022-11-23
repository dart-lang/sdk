// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  int get foo => 0;
}

extension on A {
  void set foo(int value) {}
}

typedef R = ({int foo});

extension on R {
  void set foo(int value) {}
}

test(A a, R r) {
  a.foo; // Ok.
  a.foo = 1; // Error.
  r.foo; // Ok.
  r.foo = 2; // Error.
}