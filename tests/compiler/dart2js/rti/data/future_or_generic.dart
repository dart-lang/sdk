// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:async';

/*spec:nnbd-off|prod:nnbd-off.class: global#Future:deps=[A],implicit=[Future<A.T>],indirect,needsArgs*/
/*spec:nnbd-sdk|prod:nnbd-sdk.class: global#Future:deps=[A],implicit=[Future<A.T*>],indirect,needsArgs*/

/*spec:nnbd-off|prod:nnbd-off.class: A:explicit=[FutureOr<A.T>],implicit=[A.T,Future<A.T>],indirect,needsArgs*/
/*spec:nnbd-sdk|prod:nnbd-sdk.class: A:explicit=[FutureOr<A.T*>*],implicit=[A.T,Future<A.T*>],indirect,needsArgs*/
class A<T> {
  m(o) => o is FutureOr<T>;
}

// TODO(johnniwinther): Do we need the implied `Future<B>` test in `A.m`?
/*class: B:implicit=[B]*/
class B {}

main() {
  new A<B>().m(new B());
}
