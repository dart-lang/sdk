// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String f(a, [b]) => "$a, $b";

String a<T1, T2>(int x) {
  return "a<$T1, $T2>($x)";
}

typedef b = int;
typedef c = String;

main() {
  expect("${a<b, c>}, null", f(a<b, c>.toString()));
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}