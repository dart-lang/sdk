// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

class A {}

class B extends A {}

class Foo<T> {}

T cast<T>(dynamic x) => x as T;

void test(Foo<A> Function(dynamic) f) {
  var foo = Foo<B>();
  Expect.identical(foo, f(foo));
}

void main() {
  test(cast);
}
