// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type E1(Future<int> it) {}

extension type E2(Future<int> it) implements E1, Future<int> {}

extension type E3(Future<int> it) implements Future<int> {}

test1<X extends E1, Y extends E2>(X x) async {
  // `X` is incompatible with await.
  // `Y` derives a future type.
  if (x is Y) {
    // The following line should stop being a compile-time error and be marked
    // as "Ok." when the following PR is merged:
    // https://github.com/dart-lang/language/pull/3574.
    await x; // Error.
  }
}

test2<X extends E3?, Y extends Null>(X x) async {
  // `X` is compatible with await.
  // `Y` does not derive a future type.
  if (x is Y) {
    await x; // Ok.
  }
}

test3<X extends E3?, Y extends E3>(X x) async {
  // `X` is compatible with await.
  // `Y` derives a future type.
  if (x is Y) {
    await x; // Ok.
  }
}

test4<X extends E1, Y extends X>(X x) async {
  // `X` is incompatible with await.
  // `Y` does not derive a future type.
  if (x is Y) {
    await x; // Error.
  }
}
