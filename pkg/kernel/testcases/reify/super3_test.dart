// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library super3_test;

import 'test_base.dart';

class A<T> {
  get foo => T;
}

class B extends A<A> {
  B();
  B.redirect() : this();
}

main() {
  new B().foo;
  new B.redirect();
}
