// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

extension type E1(Future<int> it) {}

extension type E2(Future<int> it) implements E1, Future<int> {}

extension type E3(Future<int> it) implements Future<int> {}

test1<X extends E1, Y extends E2>(X x) async {
  // `X` is incompatible with await.
  // `Y` isn't incompatible with await.
  if (x is Y) {
    await x; // Ok.
  }
}

test2<X extends FutureOr<E1>, Y extends E1>(X x) async {
  // `X` isn't incompatible with await.
  // `Y` is incompatible with await.
  if (x is Y) {
    await x; // Error.
  }
}

test3<X extends E3?, Y extends E3>(X x) async {
  // `X` isn't incompatible with await.
  // `Y` isn't incompatible with await.
  if (x is Y) {
    await x; // Ok.
  }
}

test4<X extends E1, Y extends X>(X x) async {
  // `X` is incompatible with await.
  // `Y` is incompatible with await.
  if (x is Y) {
    await x; // Error.
  }
}
