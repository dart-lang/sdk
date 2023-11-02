// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inline-class

import 'package:expect/expect.dart';

abstract class A<T> {
  (Object?, dynamic, dynamic) method(T t);
}

abstract class B<T> {
  (dynamic, Object?, dynamic) method(T t);
}

abstract class C<T> implements A<T>, B<T> {}

abstract class D<T> {
  (dynamic, dynamic, Object?) method(T t);
}

abstract class E<T> implements C<T>, D<T> {}

extension type F<T>(C<T> c) implements A<T>, B<T> {}

extension type G<T>(E<T> e) implements F<T>, D<T> {}

class EImpl<T> implements E<T> {
  (int, int, int) method(T t) => (1, 2, 3);
}

method<T>(G<T> g, T t) {
  Expect.equals((1, 2, 3), g.method(t));
}

main() {
  method<int>(G<int>(EImpl<int>()), 0);
  method<String>(G<String>(EImpl<String>()), '');
}