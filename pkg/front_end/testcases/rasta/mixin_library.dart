// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library test.mixin_library;

f() => 2;

V() => 87;

_private() => 117;

class Mixin<T> {
  var x = f(), y, z;
  T t;
  foo() => super.foo() + f();
  T g(T a) => null;
  h() => V();
  l() => _private();
  _privateMethod() => 49;
  publicMethod() => _privateMethod();
}

foo(m) => m._privateMethod();
