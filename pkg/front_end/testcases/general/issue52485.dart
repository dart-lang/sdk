// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

Future<void> h1<X extends Future<A>?>(X x) async {
  var x2 = await x; // Expected type for `x2` is `A?`.
  expectEquals(x2, null);
  expectEquals([x2].runtimeType, List<A?>);
  x2 = null; // Ok.
  x2 = new A(); // Ok.
}

void main() async => await h1<Null>(null);

expectEquals(a, b) {
  if (a != b) {
    throw "Expected '${a}' to be equal to '${b}'.";
  }
}
