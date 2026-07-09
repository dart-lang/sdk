// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

class C<T> {
  void test2c(FutureOr<T> x) {}
  void test3c(Future<T> x) {}
  void test4c(FutureOr<T> x) {}

  void test2r(C<FutureOr<T>> x) {}
  void test3r(C<Future<T>> x) {}
  void test4r(C<FutureOr<T>> x) {}
  void test5r(C<Future<T>> x) {}
  void test6r(C<FutureOr<T>> x) {}
  void test7r(C<T> x) {}
  void test8r(C<T> x) {}
}

main() {
  dynamic c = C<int>();

  c.test2c(3);
  c.test3c(Future.value(3));
  c.test4c(Future.value(3));

  c.test2r(C<int>());
  c.test3r(C<Future<int>>());
  c.test4r(C<Future<int>>());
  c.test5r(C<FutureOr<int>>());
  c.test6r(C<FutureOr<int>>());
  c.test7r(C<FutureOr<int>>());
  c.test8r(C<Future<int>>());
}
