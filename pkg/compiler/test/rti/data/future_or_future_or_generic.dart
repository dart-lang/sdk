// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:async';

/*spec.class: global#Future:deps=[A],implicit=[Future<B<A.T*>*>,Future<C*>],indirect,needsArgs*/

/*class: A:explicit=[FutureOr<B<A.T*>*>*],implicit=[B<A.T*>,Future<B<A.T*>*>],indirect,needsArgs*/
class A<T> {
  m(o) => o is FutureOr<B<T>>;
}

/*class: B:deps=[A],explicit=[FutureOr<B<A.T*>*>*],implicit=[B<A.T*>,Future<B<A.T*>*>],needsArgs*/
class B<T> {}

/*class: C:implicit=[C,Future<C*>,FutureOr<C*>]*/
class C {}

main() {
  new A<FutureOr<C>>().m(new B<C>());
}
