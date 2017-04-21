// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library superclass_test;

import 'test_base.dart';

class X {}

class Y {}

class R<T> {}

class A<T> {
  foo() => new R<T>();
}

class B<T> extends A<T> {}

class C<T> extends A<Y> {}

class D<T> extends B<R<T>> {}

main() {
  expectTrue(new A<X>().foo() is R<X>);
  expectTrue(new B<X>().foo() is R<X>);
  expectTrue(new C<X>().foo() is R<Y>);
  expectTrue(new D<X>().foo() is R<R<X>>);

  expectTrue(new A<X>().foo() is! R<Y>);
  expectTrue(new B<X>().foo() is! R<Y>);
  expectTrue(new C<X>().foo() is! R<X>);
  expectTrue(new D<X>().foo() is! R<R<Y>>);
}
