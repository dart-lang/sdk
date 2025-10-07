// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

class Foo {
  const Foo(List<String> l);
}

void test() {
  for (@Foo(const []) int i = 0; i < 1; i++) {}
  for (@Foo(const []) int i in [0]) {}
}

main() {}
