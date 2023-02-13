// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

enum E<X extends A> {
  element,
}

main() {
  expectEquals("${E.values.runtimeType}", "List<E<A>>");
}

expectEquals(x, y) {
  if (x != y) {
    throw "Expected '${x}' to be equals to '${y}'.";
  }
}
