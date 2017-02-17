// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library factories_test;

import 'test_base.dart';

class A<T> {
  factory A() {
    return new B<T>();
  }

  factory A.named() {
    return new A<T>.internal();
  }

  factory A.forward() = A<T>.internal;

  A.internal();
}

class B<T> extends A<T> {
  B() : super.internal();
}

class X {}

class Y {}

main() {
  expectTrue(new A<X>.named() is A<X>);
  expectTrue(new A<X>.named() is! A<Y>);
  expectTrue(new A<X>.forward() is A<X>);
  expectTrue(new A<X>.forward() is! A<Y>);
  expectTrue(new A<X>() is B<X>);
  expectTrue(new A<X>() is! B<Y>);
  expectTrue(new A<X>.named() is! B<X>);
  expectTrue(new A<X>.forward() is! B<X>);
}
