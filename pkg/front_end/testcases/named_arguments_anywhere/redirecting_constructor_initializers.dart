// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  A(int x, {required String y});

  A.foo() : this(y: "foo", 42);

  factory A.bar(int x, {required String y}) = A;
}

class B extends A {
  B() : super(y: "foo", 42);
}

test() {
  new A.bar(42, y: "bar");
  new A.bar(y: "bar", 42);
}

main() {}
