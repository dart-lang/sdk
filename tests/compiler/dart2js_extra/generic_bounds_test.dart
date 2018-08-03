// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--strong

import 'package:expect/expect.dart';

class A {}

class B extends A {}

class C {}

class D<T> {}

class E<T> extends D<T> {}

class F<T> {}

void f1<T extends A>() {
  print('f1<$T>');
}

void f2<S, T extends D<S>>() {
  print('f2<$S,$T>');
}

main() {
  dynamic f = f1;
  f<A>();
  f<B>();
  Expect.throws(() => f<C>(), (e) {
    print(e);
    return true;
  });
  f();
  f = f2;
  f<A, D<A>>();
  f<A, E<A>>();
  Expect.throws(() => f<A, F<A>>(), (e) {
    print(e);
    return true;
  });
  f();
}
