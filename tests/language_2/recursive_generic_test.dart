// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

abstract class S<T extends S<T>> {
  m() => 123;
  get S_T => T;
}

class C<T extends C<T>> extends S<C<T>> {
  m() => 456;
  get C_T => T;
}

class D extends C<D> {}

main() {
  regress31434();

  Expect.equals(new C<D>().m(), 456);
  Expect.equals(new C<D>().C_T, D);
  Expect.equals(new C<D>().S_T.toString(), 'C<D>');
}

class F<L, R> {}

class E<L, R> extends F<E<L, Object>, R> {}

regress31434() {
  type<T>() => T;
  dynamic e = new E<int, String>();
  Expect.equals(e.runtimeType, type<E<int, String>>());
}
