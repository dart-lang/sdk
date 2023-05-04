// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  final (num, {String name}) r;
  const C(int i, String s): r = (i + 1, name: s + "!");
}

main() {
  const c = const C(42, "Hi");
  expect(43, c.r.$1);
  expect("Hi!", c.r.name);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}