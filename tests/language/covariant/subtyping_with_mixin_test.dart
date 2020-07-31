// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class A {}

class B extends A {}

class Base<S> {}

class Mixin<T> {
  void f(T arg) {}
}

abstract class Interface {
  void f(covariant A arg);
}

class C<S> extends Base<S> with Mixin<B> implements Interface {}

main() {
  Interface i = new C<String>();
  i.f(new B());
  Expect.throwsTypeError(() {
    i.f(new A());
  });
}
