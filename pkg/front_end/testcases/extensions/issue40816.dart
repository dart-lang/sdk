// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

class B {}

extension on A {
  void foo(A a, B b) {}
}

void main() {
  dynamic a = A();
  dynamic b = B();
  A().foo(a, b);
}
