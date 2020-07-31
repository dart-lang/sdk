// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class F<T> {
  T foo(T t);
}

class B<T extends F<T>> {}

class C<T extends F<C<T>>> {}

class D extends B<D> implements F<D> {
  D foo(D x) => x;
}

class E extends C<E> implements F<C<E>> {
  C<E> foo(C<E> x) => x;
}

main() {
  D fd = D();
  var d = fd.foo(fd);
  print(d);
  E fe = E();
  var e = fe.foo(fe);
  print(e);
}
