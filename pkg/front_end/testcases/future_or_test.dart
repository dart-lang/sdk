// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The test checks that an expression with static type Future<dynamic> is
// accepted as a return expression of a method with an async body and the
// declared return type Future<int>.

import 'dart:async';

class A {
  dynamic foo() => null;
}

class B {
  A a;

  Future<dynamic> bar() async => a.foo();
}

class C {
  B b = B();

  Future<int> baz() async => b.bar();
}

main() {}
