// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  A(int x, bool y, {required String z});

  A.foo() : this(42, z: "foo", false);

  factory A.bar(int x, bool y, {required String z}) = A;
}

class B extends A {
  B() : super(42, z: "foo", false);
}

test() {
  new A.bar(42, false, z: "bar");
  new A.bar(42, z: "bar", false);
  new A.bar(z: "bar", 42, false);
}

main() {}
