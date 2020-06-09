// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Regression test for https://github.com/dart-lang/sdk/issues/36374.
//
// Bytecode flow graph builder should be able to correctly handle non-empty
// expression stack when throwing an exception: dropping some of the entries,
// while keeping entries which could still be used.
//
// VMOptions=--optimization_counter_threshold=10 --deterministic

class Foo {
  Foo(int x);
}

class Bar {
  Bar(String y, Foo z);
}

foo(Object arg) {
  return Bar('abc', arg == null ? null : Foo((throw 'Err')));
}

main() {
  for (int i = 0; i < 20; ++i) {
    foo(null);
  }
}
