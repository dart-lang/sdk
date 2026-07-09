// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  print(B().foo);
}

abstract class A {
  A();

  factory A.redir({double foo}) = B;
}

class B<T> extends A {
  B({this.foo = 10});
  final double foo;
}
