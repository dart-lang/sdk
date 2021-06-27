// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  dynamic operator*(dynamic other) => 42;
  dynamic operator[](int index) => 42;
  void operator[]=(int index, dynamic value) {}
  dynamic operator-() => 42;
}

extension E on A {
  dynamic operator+(dynamic other) => 42;
}

extension type ET on A {
  dynamic operator~/(dynamic other) => 42;
}

test(A a, E e, ET et) {
  a * "foobar"; // Ok.
  a[0]; // Ok.
  a[0] = "foobar"; // Ok.
  -a; // Ok.
  a + "foobar"; // Ok.
  a ~/ "foobar"; // Error.

  e * "foobar"; // Error.
  e[0]; // Error.
  e[0] = "foobar"; // Error.
  -e; // Error.
  e + "foobar"; // Ok.
  e ~/ "foobar"; // Error.

  et * "foobar"; // Error.
  et[0]; // Error.
  et[0] = "foobar"; // Error.
  -et; // Error.
  et + "foobar"; // Error.
  et ~/ "foobar"; // Ok.
}

main() {}
