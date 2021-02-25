// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const int foo = 42 * 42;
const String bar =
    "hello" " " "${String.fromEnvironment("baz", defaultValue: "world")}" "!";
const bool baz = true && true && (false || true) && (42 == 21 * 4 / 2);
const blaSymbol = #_x;

main() {
  _x();
  const bool.fromEnvironment("foo");
  print(bar);
}

void _x() {
  print(foo);
  print(bar);
}
