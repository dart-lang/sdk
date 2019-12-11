// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Regression test for issue 6353.

class A<E> {}

class C<E> extends A<E> {
  forEach(callback(E element)) {}
}

class D<E> {
  lala(E element) {}
}

main() {
  var c = new C<int>();
  c.forEach(new D<int>().lala);
}
