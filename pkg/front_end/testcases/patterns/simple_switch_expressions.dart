// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1(dynamic x) {
  return switch (x) {
    0 => "zero",
    _ => "other"
  };
}

test2(String x) {
  return switch (x) {
    "zero" => 0,
    _ => 1
  };
}

main() {
  expectEquals(test1(0), "zero");
  expectEquals(test1(null), "other");
  expectEquals(test1([]), "other");

  expectEquals(test2("zero"), 0);
  expectEquals(test2("one"), 1);
  expectEquals(test2("two"), 1);
}

expectEquals(x, y) {
  if (x != y) {
    throw "Expected ${x} to be equal to ${y}.";
  }
}
