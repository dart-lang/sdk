// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef C<A, K> = int Function<B>(A x, K y, B v);
typedef D<K> = C<A, K> Function<A>(int z);

dynamic producer<K>() {
  return <A>(int v1) {
    return <B>(A v2, K v3, B v4) => 0;
  };
}

main() {
  assert(producer<String>() is D<String>);
}
