// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

extension type E1(Future<int> foo) {}
extension type E2<X extends Future<String>>(X foo) {}
extension type E3(FutureOr<bool> foo) {}
extension type E4<X extends FutureOr<double>>(X foo) {}
extension type E5<X>(X foo) {}

extension type F1(Future<int> foo) implements Future<int> {}
extension type F2<X extends Future<num>>(X foo) implements Future<num> {}
extension type F3<X extends Future<Object>>(X foo) implements Future<Object> {}
extension type F4<X extends Future<num>>(X foo) implements F3<X> {}

test(
    E1 e1, E2<Future<String>> e2, E3 e3, E4<Future<double>> e4, E5<Object> e5object, E5<Future<num>> e5future,
    F1 f1, F2<Future<num>> f2, F3<Future<String>> f3, F4<Future<int>> f4) async {
  await e1; // Error.
  await e2; // Error.
  await e3; // Error.
  await e4; // Error.
  await e5object; // Error.
  await e5future; // Error.

  await f1; // Ok.
  await f2; // Ok.
  await f3; // Ok.
  await f4; // Ok.
}
