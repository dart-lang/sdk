// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum E {
  one("foo"),
  two("bar");

  final String field;

  const E(this.field);

  @override
  String toString() => field;
}

expectEquals(a, b) {
  if (a != b) {
    throw "Expected '$a' and '$b' to be equal.";
  }
}

main() {
  expectEquals("${E.one}", "foo");
  expectEquals("${E.two}", "bar");
}
