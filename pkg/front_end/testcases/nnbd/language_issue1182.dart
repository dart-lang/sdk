// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension Test<T> on T {
  T Function(T) get test => (a) => this;
}

class Foo<S extends num> {
  void test1(S x) {
    S Function(S) f = x.test;
  }
}

void main() {}
