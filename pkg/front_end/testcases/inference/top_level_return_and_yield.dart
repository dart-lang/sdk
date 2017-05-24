// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:async';

typedef int IntToInt(int i);

IntToInt a() {
  return /*@returnType=int*/ (/*@type=int*/ x) => x;
}

Future<IntToInt> b() async {
  // TODO(paulberry): this is broken due to bug 29689.
  return /*@returnType=dynamic*/ (/*@type=dynamic*/ x) => x;
}

Iterable<IntToInt> c() sync* {
  yield /*@returnType=int*/ (/*@type=int*/ x) => x;
}

Iterable<IntToInt> d() sync* {
  yield* /*@typeArgs=(int) -> int*/ [
    /*@returnType=int*/ (/*@type=int*/ x) => x
  ];
}

Stream<IntToInt> e() async* {
  yield /*@returnType=int*/ (/*@type=int*/ x) => x;
}

Stream<IntToInt> f() async* {
  yield* new /*@typeArgs=(int) -> int*/ Stream.fromIterable(
      /*@typeArgs=(int) -> int*/ [/*@returnType=int*/ (/*@type=int*/ x) => x]);
}

main() {}
