// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X> {
  A.foo() {}
  factory A.bar() => new A.foo();
  factory A.baz() = A.bar;
}

test() {
  List.filled; // Ok.
  A.foo; // Ok.
  A.bar; // Ok.
  A.baz; // Ok.

  List<int>.filled; // Ok.
  A<int>.foo; // Ok.
  A<int>.bar; // Ok.
  A<int>.baz; // Ok.

  List.filled<int>; // Error.
  A.foo<int>; // Error.
  A.bar<int>; // Error.
  A.baz<int>; // Error.
}

main() {}
