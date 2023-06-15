// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code as governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  final String name;
  const A(this.name);

  String toString() => name;
}

main() {
  // Although the order of fields in toString() is unspecified,
  // this test assumes that positional fields are printed first and
  // named fields are sorted lexicographically.
  // This test might need more sophisticated checks if there is
  // an implementation which doesn't follow that order.

  Expect.equals("(1, 2)", (1, 2).toString());
  Expect.equals("(1, 2)", (const (1, 2)).toString());
  Expect.equals("(3, 2, 1)", (3, 2, 1).toString());

  Expect.equals("(1, foo: 2)", (1, foo: 2).toString());
  Expect.equals("(1, foo: 2)", (foo: 2, 1).toString());

  Expect.equals(
      "(1, abc, bar: 3, foo: 2)", (1, foo: 2, "abc", bar: 3).toString());

  Expect.equals(
      "((A1, A2), (foo: A3), (A7, bar: A5, baz: A6, foo: A4))",
      (
        (A("A1"), A("A2")),
        const (foo: A("A3")),
        (foo: A("A4"), bar: A("A5"), baz: A("A6"), A("A7"))
      )
          .toString());
}
