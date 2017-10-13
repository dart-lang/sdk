// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef T F<T>(T t);

class B<T extends F<T>> {}

class C<T extends F<C<T>>> {}

class D extends B<D> {
  D foo(D x) => x;
  D call(D x) => x;
  D bar(D x) => x;
}

class E extends C<E> {
  C<E> foo(C<E> x) => x;
  C<E> call(C<E> x) => x;
  C<E> bar(C<E> x) => x;
}

main() {
  F<D> fd = new D();
  var d = fd(fd);
  print(d);
  F<E> fe = new E();
  var e = fe(fe);
  print(e);
}
